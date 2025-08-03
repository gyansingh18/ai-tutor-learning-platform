class PdfProcessorJob < ApplicationJob
  queue_as :default

  def perform(pdf_material_id)
    pdf_material = PdfMaterial.find(pdf_material_id)
    processor = PdfProcessorService.new(pdf_material)

    if processor.process
      Rails.logger.info "PDF processing completed for #{pdf_material.title}"
    else
      Rails.logger.error "PDF processing failed for #{pdf_material.title}"
    end
  rescue => e
    Rails.logger.error "PDF Processor Job Error: #{e.message}"
  end
end
