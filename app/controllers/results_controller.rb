class ResultsController < ApplicationController
  layout 'standard'
  def index
  end
  
  def report_20100125
    render :partial=> "report_20100125"
  end

  def report_20100126
    render :partial=> "report_20100126"
  end

end
