class UploadsController < ApplicationController
    layout 'standard'

    before_filter :require_user, :except => [:index, :download, :datafiles]

    # GET /uploads
    # GET /uploads.xml
    def index
        unless params[:cd].blank?
            if params[:cd].first == '/'
                set_session_dir(params[:cd])
            else
                if params[:cd] == 'up'
                    session_dir = session_directory()
                    unless session_dir == '/'
                        set_session_dir(session_dir.split('/')[0..-2].join('/'))
                    end
                else
                    set_session_dir(_child_abs_path(params[:cd]))
                end
                redirect_to(uploads_path(:cd => session_directory())) && return
            end
            params[:cd] = ''
        else
            redirect_to(uploads_path(:cd => session_directory())) && return
        end

        publicness = ' AND `public`=1'
        if current_user
            publicness = ''
        end

        @uploads = Upload.all(
            :conditions => [
                '`directory` LIKE ? AND `deleted`=0' + publicness,
                session_directory() + '%'],
            :order => :directory)

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @uploads }
        end
    end

    # GET /uploads/1
    # GET /uploads/1.xml
    def show
        @upload = Upload.find(params[:id])

        respond_to do |format|
            format.html # show.html.erb
            format.xml  { render :xml => @upload }
        end
    end

    # GET /uploads/new
    # GET /uploads/new.xml
    def new
        @upload = Upload.new

        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @upload }
        end
    end

    # GET /uploads/1/edit
    def edit
        @upload = Upload.find(params[:id])
    end

    # POST /uploads
    # POST /uploads.xml
    def create
        unless _allowed_to_edit
            render :text => DISALLOWED_TEXT, :status => :unauthorized and return
        end

        if params[:package]
            package_upload()
            redirect_to(uploads_path)
            return
        end

        @upload = Upload.new(params[:upload])

        @upload.directory = session_directory()
        @upload.user = current_user

        respond_to do |format|
            if @upload.save
                msg = 'Uploaded successfully.'
                flash.now[:notice] = msg
                format.html { redirect_to(@upload, :notice => msg) }
                format.xml  { render :xml => @upload, :status => :created, :location => @upload }
            else
                format.html { render :action => "new" }
                format.xml  { render :xml => @upload.errors, :status => :unprocessable_entity }
            end
        end
    end

    # PUT /uploads/1
    # PUT /uploads/1.xml
    def update
        unless _allowed_to_edit
            render :text => DISALLOWED_TEXT, :status => :unauthorized and return
        end
        @upload = Upload.find(params[:id])

        respond_to do |format|
            if @upload.update_attributes(params[:upload])
                msg = 'File was successfully updated.'
                flash.now[:notice] = msg
                format.html { redirect_to(@upload, :notice => msg) }
                format.xml  { head :ok }
            else
                format.html { render :action => "edit" }
                format.xml  { render :xml => @upload.errors, :status => :unprocessable_entity }
            end
        end
    end

    # DELETE /uploads/1
    # DELETE /uploads/1.xml
    def destroy
      @upload = Upload.find(params[:id])
      @upload.deleted = 1
      @upload.save

      respond_to do |format|
        format.html { redirect_to(uploads_url) }
        format.xml  { head :ok }
      end
    end

    # GET /uploads/download_dir
    def download_dir
        if not current_user
            require_user && return
        end
        dir = params[:cd]
        file_name = dir.gsub('/', '-') + '.zip'
        # Strip leading -
        if file_name =~ /^-/
            file_name = file_name.slice(1..-1)
        end

        uploads = Upload.all(
            :select => ['id', 'directory', 'filename', 'public'].join(','),
            :conditions => ['deleted = 0 AND directory LIKE ?', "#{dir}"])

        t = Tempfile.new(file_name)
        Zip::ZipOutputStream.open(t.path) do |z|
            uploads.each do |up|
                z.put_next_entry(up.filename)
                begin
                    z.print IO.read(up.public_filename)
                rescue Errno::ENOENT
                    z.print ''
                end
            end
        end
        send_file t.path, :type => 'application/zip',
                          :disposition => 'attachment',
                          :filename => file_name
        t.close
    end

    # GET /uploads/1/download
    def download
        file = Upload.find(params[:id])
        if file and not file.deleted
            if not file.public and not current_user
                flash.now[:notice] = "Please sign in to view non-public files"
                require_user
            else
                # Instruct nginx to send the file using X-Accel-Redirect.
                # Sending large files through Rails will lock up the process.
                begin
                    filepath = file.public_filename.sub(RAILS_ROOT, '')
                    response.headers['X-Accel-Redirect'] = filepath
                    response.headers['Content-Type'] = 
                        file.content_type or 'application/octet-stream'
                    response.headers['Content-Disposition'] =
                        "inline; filename=\"#{file.filename}\""
                    render :nothing => true
                rescue => e
                    Rails.logger.error(e)
                    render :nothing => true, :status => :bad_request
                end
            end
        else
            raise ActionController::RoutingError.new('Not Found')
        end
    end

    def mvdir
        @currdir = session_directory()
        @child = params[:cd]

        if params[:commit] == 'Rename'
            if params[:name] =~ /[\/\.]/
                flash.now[:notice] = "Illegal directory name"
                render :layout => 'standard', :status => :bad_request
                return
            end

            old_root = _child_abs_path(@child)

            uploads = Upload.all(
                :select => ['id', 'directory', 'filename', 'public'].join(','),
                :conditions => ['directory LIKE ?', "#{old_root}%"])

            @child = params[:name]
            new_root = _child_abs_path(@child)

            if Upload.exists?(['directory LIKE ?', "#{new_root}%"])
                flash.now[:notice] = "Directory name already exists"
                render :layout => 'standard', :status => :bad_request
                return
            end

            ActiveRecord::Base.transaction do
                for upload in uploads
                    upload.directory = upload.directory.sub(old_root, new_root)
                    upload.save(false)
                end
            end

            flash[:notice] = "Successfully renamed directory #{old_root} to " + 
                "#{new_root}"
            redirect_to(uploads_path)
        end
    end

    def datafiles
        path = File.join(params[:path])
        dir, filename = File.split(path)
        if dir == '.'
            dir = File::SEPARATOR
        else
            dir = File.join(File::SEPARATOR, dir)
        end

        upload = Upload.first(
            :conditions => {:directory => dir, :filename => filename})
        if upload
            redirect_to upload_get_path(upload.id)
        else
            raise ActionController::RoutingError.new('Not Found')
        end
    end

    private

    def _child_abs_path(child)
        session_dir = session_directory()
        if session_dir.last != '/'
            session_dir += '/'
        end
        "#{session_dir}#{child}"
    end

    DISALLOWED_TEXT = 'You must be signed in as dimes.'

    def _allowed_to_edit
        return current_user == User.first(:conditions => {'login' => 'dimes'})
    end

    def session_directory
        session[controller_name] ? session[controller_name][:directory] || '/' : '/'
    end

    def set_session_dir(value)
        session[controller_name] = {} if session[controller_name].blank?
        value = '/' if value.blank?
        session[controller_name][:directory] = value
    end

    def guess_mime_type(basename)
        Mime::Type.lookup_by_extension(
            File.extname(basename).downcase.tr('.', '')
        ) || 'application/octet-stream'
    end

    def package_upload
        Rails.logger.debug('uploading package')

        publicness = params[:upload][:public]
        description = params[:upload][:description]
        tempfile = params[:upload][:uploaded_data]

        if tempfile.kind_of?(StringIO)
            tmp = TempFile.new(tempfile.original_filename) do |f|
                f.write(tempfile.to_s)
            end
            tempfile = tmp
        end

        skip_present = false
        cwd = session_directory()

        Zip::ZipFile.open(tempfile.path) do |zf|
            zf.entries.each do |f|
                next if f.name =~ /^__MACOSX\//
                next if f.directory?
                dirname, basename = File.split(f.name)
                if dirname == '.'
                    dir = cwd
                else
                    dir = File.join(cwd, dirname)
                end
                Rails.logger.debug("#{dir} \t #{basename}")

                upload = Upload.first(:conditions => {
                    :directory => dir, :filename => basename,
                    :deleted => false})
                if upload
                    upload.deleted = true
                    upload.save
                end

                upload = Upload.new()
                upload.public = publicness
                upload.directory = dir
                upload.set_temp_data(f.get_raw_input_stream.read)
                upload.content_type = guess_mime_type(basename)
                upload.filename = basename
                upload.user = current_user
                upload.save
            end
        end
        flash[:notice] = 'Package uploaded'
    end
end
