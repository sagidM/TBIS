class CompaniesController < ApplicationController
  before_action :ensure_current_user
  before_action :set_people
  before_action :set_company
  before_action :set_access
  before_action :set_affiliate
  before_action :confirm_actions, except: [:new, :create]
  layout 'card'

  def add_field
    @new_block = InfoBlock.new
    @new_template_field = FieldTemplate.new
    @blocks_clients = InfoBlock.where(company_id: @current_company.id, model_object: 'clients')
    @field_templates_clients = FieldTemplate.where(block_id: @blocks_clients)
  end
  
  # GET /companies
  # GET /companies.json
  def index
    @companies = Company.where(user: current_user)
    
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    @company = Company.find(params[:id])
  end

  # GET /companies/new
  def new
    @company = Company.new
  end

  # GET /companies/1/edit
  def edit
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(company_params)

    success_saving = ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @company.save
      user = company_params[:user]

      people = Client.create(
        first_name: user.first_name, last_name: user.last_name, 
        company_id: @company.id, sex: 0, 
        user_id: user.id, role: (Client::Role::STUFF).to_s(2).to_i)

      user.update_attribute(:people_id, people.id)

      Work.create(position_work: :director, people_id: people.id)

      # user.role |= User::Role::COMPANY_OWNER
      user.save!
    end

    respond_to do |format|
      if success_saving
        format.html { redirect_to root_path, notice: t('company.created') }
        format.json { render :show, status: :created, location: @company }
      else
        format.html { render :new }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    respond_to do |format|
      if @company.update(company_params)
        format.html { redirect_to @company, notice: t('company.updated') }
        format.json { render :show, status: :ok, location: @company }
      else
        format.html { render :edit }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  # def destroy
  #   @company.destroy
  #   respond_to do |format|
  #     format.html { redirect_to companies_url, notice: t('company.destroyed') }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def company_params
      params.require(:company).permit(:name).merge(user: current_user)
    end

    def ensure_company_owner
      redirect_to action: :new if current_user.role & User::Role::COMPANY_OWNER == 0
    end
end
