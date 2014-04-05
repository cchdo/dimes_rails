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

    def cruise_reports
    end

    def bibliography
    end

    def zotero
        # JSON output for zotero bibliography

        # initialize the virtualenv if needed
        venvdir = Rails.root.join('tmp', 'zotero_venv')
        unless File.directory?(venvdir)
            `virtualenv "#{venvdir}"`
            `#{venvdir}/bin/pip install pyzotero`
        end
        python = "#{venvdir}/bin/python"
        script = Rails.root.join('app', 'controllers', 'zotero.py')

        # fetch from zotero if needed
        cache_file = Rails.root.join('tmp', 'zotero_cache.json')
        reload = false
        unless File.exists?(cache_file)
            reload = true
        else
            now = Time.now.to_i
            delta = now - File.mtime(cache_file).to_i 
            if delta > 60 * 5
                reload = true
            end
        end
        if reload
            `#{python} "#{script}" > "#{cache_file}"`
        end
        render :file => cache_file, :content_type => "application/json"
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
