class PdfMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_pdf_material, only: [:show, :destroy]

  def index
    @pdf_materials = PdfMaterial.includes(:chapter, :user).all
    @chapters = Chapter.ordered.includes(:subject => :grade)
  end

  def show
  end

  def new
    @pdf_material = PdfMaterial.new
    @chapters = Chapter.ordered.includes(:subject => :grade)
  end

  def create
    @pdf_material = current_user.pdf_materials.build(pdf_material_params)

    if @pdf_material.save
      # Process PDF in background
      PdfProcessorJob.perform_later(@pdf_material.id)

      redirect_to @pdf_material, notice: 'PDF uploaded successfully! Processing will begin shortly.'
    else
      @chapters = Chapter.ordered.includes(:subject, :grade)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @pdf_material.destroy
    redirect_to pdf_materials_path, notice: 'PDF deleted successfully!'
  end

  private

  def set_pdf_material
    @pdf_material = PdfMaterial.find(params[:id])
  end

  def pdf_material_params
    params.require(:pdf_material).permit(:title, :chapter_id, :pdf_file)
  end

  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end
