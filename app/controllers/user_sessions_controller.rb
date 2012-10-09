class UserSessionsController < ApplicationController
  layout 'standard'
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    if params[:return_to]
        session[:return_to] = params[:return_to]
    end
    @user_session = UserSession.new
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      login = ''
      unless current_user.nil?
        login = " #{current_user.login}"
      end
      flash[:info] = "Welcome#{login}!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:info] = "Goodbye!"
    redirect_back_or_default new_user_session_url
  end
end
