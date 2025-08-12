class SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:q]&.strip
    @results = {}

    if @query.present? && @query.length >= 2
      # Search chapters
      @results[:chapters] = Chapter.joins(:subject => :grade)
                                  .where("chapters.name ILIKE ? OR chapters.description ILIKE ?",
                                         "%#{@query}%", "%#{@query}%")
                                  .includes(:subject => :grade)
                                  .limit(10)

      # Search subjects
      @results[:subjects] = Subject.joins(:grade)
                                  .where("subjects.name ILIKE ? OR subjects.description ILIKE ?",
                                         "%#{@query}%", "%#{@query}%")
                                  .includes(:grade)
                                  .limit(10)

      # Search PDF materials
      @results[:pdf_materials] = PdfMaterial.joins(:chapter => {:subject => :grade})
                                           .where("pdf_materials.title ILIKE ?", "%#{@query}%")
                                           .includes(:chapter => {:subject => :grade})
                                           .limit(10)

      # Search vector chunks for content search
      @results[:content] = VectorChunk.joins(:pdf_material => {:chapter => {:subject => :grade}})
                                     .where("vector_chunks.content ILIKE ?", "%#{@query}%")
                                     .includes(:pdf_material => {:chapter => {:subject => :grade}})
                                     .limit(15)

      @total_results = @results.values.map(&:count).sum
    else
      @total_results = 0
    end

    respond_to do |format|
      format.html
      format.json { render json: format_json_results }
    end
  end

  private

  def format_json_results
    return { results: [], total: 0 } if @query.blank?

    results = []

    # Format chapters
    @results[:chapters].each do |chapter|
      results << {
        type: 'chapter',
        id: chapter.id,
        title: chapter.name,
        subtitle: "#{chapter.subject.name} • #{chapter.subject.grade.display_name}",
        url: grade_subject_chapter_path(chapter.subject.grade, chapter.subject, chapter)
      }
    end

    # Format subjects
    @results[:subjects].each do |subject|
      results << {
        type: 'subject',
        id: subject.id,
        title: subject.name,
        subtitle: "#{subject.grade.display_name} • #{pluralize(subject.chapters.count, 'chapter')}",
        url: grade_subject_path(subject.grade, subject)
      }
    end

    # Format PDF materials
    @results[:pdf_materials].each do |pdf|
      results << {
        type: 'pdf',
        id: pdf.id,
        title: pdf.title,
        subtitle: "#{pdf.chapter.name} • #{pdf.chapter.subject.name}",
        url: grade_subject_chapter_path(pdf.chapter.subject.grade, pdf.chapter.subject, pdf.chapter)
      }
    end

    { results: results.first(20), total: @total_results }
  end
end
