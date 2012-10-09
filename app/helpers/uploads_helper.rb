module UploadsHelper
    def curr_dir
        session[controller_name] ? session[controller_name][:directory] || '/' : '/'
    end

    def parent_dir
        File.join(File.split(curr_dir())[0])
    end

    def child(p)
        curr = curr_dir.split('/')
        curr = [''] if curr.empty?
        path = p.split('/')
        (path - curr).first
    end
end
