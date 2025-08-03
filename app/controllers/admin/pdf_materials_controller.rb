class Admin::PdfMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_pdf_material, only: [:show, :destroy]

  def index
    @pdf_materials = PdfMaterial.recent.includes(:chapter, :user)
  end

  def show
  end

  def new
    @pdf_material = PdfMaterial.new
    # Preload grades with subjects and chapters for the JavaScript
    @grades = Grade.includes(subjects: :chapters).ordered
  end

  def create
    # Extract grade_id and subject_id for chapter creation logic
    grade_id = params[:pdf_material][:grade_id]
    subject_id = params[:pdf_material][:subject_id]

    # Build pdf_material with only valid attributes
    @pdf_material = current_user.pdf_materials.build(pdf_material_params)

    # Handle new chapter creation if requested
    if params[:pdf_material][:new_chapter_name].present?
      # Find the selected subject
      if subject_id.present?
        # Create new chapter
        new_chapter = Chapter.new(
          name: params[:pdf_material][:new_chapter_name],
          description: params[:pdf_material][:new_chapter_description],
          subject_id: subject_id
        )

        if new_chapter.save
          @pdf_material.chapter = new_chapter
        else
          @pdf_material.errors.add(:base, "Failed to create new chapter: #{new_chapter.errors.full_messages.join(', ')}")
          @grades = Grade.includes(subjects: :chapters).ordered
          return render :new, status: :unprocessable_entity
        end
      else
        @pdf_material.errors.add(:base, "Please select a valid subject for the new chapter")
        @grades = Grade.includes(subjects: :chapters).ordered
        return render :new, status: :unprocessable_entity
      end
    end

    if @pdf_material.save
      # Process PDF in background
      PdfProcessorJob.perform_later(@pdf_material.id)

      redirect_to admin_pdf_material_path(@pdf_material), notice: 'PDF uploaded successfully! Processing will begin shortly.'
    else
      @grades = Grade.includes(subjects: :chapters).ordered
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @pdf_material.destroy
    redirect_to admin_pdf_materials_path, notice: 'PDF deleted successfully!'
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
