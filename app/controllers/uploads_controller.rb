class UploadsController < ApplicationController
    layout 'standard'

    before_filter :require_user, :except => [:index, :download, :datafiles]

    # GET /uploads
    # GET /uploads.xml
    def index
        unless params[:cd].blank?
            if params[:cd].first == '/'
                set_session_dir(params[:cd])
            elsif params[:cd] == 'up'
                session_dir = session_directory()
                unless session_dir == '/'
                    set_session_dir(session_dir.split('/')[0..-2].join('/'))
                end
            else
                session_dir = session_directory()
                if session_dir.last != '/'
                    session_dir += '/'
                end
                set_session_dir("#{session_dir}#{params[:cd]}")
            end
            params[:cd] = ''
        end

        publicness = ' AND `public`=1'
        if current_user
            publicness = ''
        end

        @uploads = Upload.all(
            :conditions => [
                '`directory` LIKE ?' + publicness, session_directory() + '%'],
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
        @upload = Upload.new(params[:upload])

        @upload.directory = session_directory()
        @upload.user = current_user

        respond_to do |format|
            if @upload.save
                msg = 'Uploaded successfully.'
                flash[:notice] = msg
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
                flash[:notice] = msg
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
    # def destroy
    #   @upload = Upload.find(params[:id])
    #   @upload.destroy

    #   respond_to do |format|
    #     format.html { redirect_to(uploads_url) }
    #     format.xml  { head :ok }
    #   end
    # end

    def download
        file = Upload.find(params[:upload_id])
        if file
            if not file.public and not current_user
                flash[:notice] = "Please sign in to view non-public files"
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
end
