class ResultsController < ApplicationController
  layout 'standard'
  def index
  end

  def body
    render :partial => params[:slug]
  rescue ActionView::MissingTemplate
    render :nothing => true
  end
end
