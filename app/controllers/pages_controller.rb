class PagesController < ApplicationController
    layout 'standard'

    def home
    end

    def outreach_0
    end

    def components
    end

    def fieldwork
    end

    def publications
    end

    def people
    end

    def calendar
    end

    def press
    end

    def data_policy
    end

    def results
        redirect_to fieldwork_path, :status => 301
    end
end
