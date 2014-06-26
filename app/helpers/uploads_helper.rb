module UploadsHelper
    def curr_dir
        session[controller_name] ? session[controller_name][:directory] || '/' : '/'
    end

    def parent_dir
        File.join(File.split(curr_dir())[0])
    end

    def child(p)
        pwd = curr_dir()
        relpath = p
        if pwd != '/'
            relpath = p.sub(pwd, '')
        end
        relpath.split('/')[1]
    end
end
