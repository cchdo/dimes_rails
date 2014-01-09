ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes"

  map.root :controller => :pages, :action => :home

  map.components   'components',   :controller => :pages, :action => :components
  map.fieldwork    'fieldwork',    :controller => :pages, :action => :fieldwork
  map.publications 'publications', :controller => :pages, :action => :publications
  map.people       'people',       :controller => :pages, :action => :people
  map.calendar     'calendar',     :controller => :pages, :action => :calendar
  map.press        'press',        :controller => :pages, :action => :press
  map.data_policy  'data_policy',  :controller => :pages, :action => :data_policy
  map.outreach_0   'outreach/DIMES_article_CB_30_June', :controller => :pages, :action => :outreach_0

  map.result_body 'results/body/:slug', :controller => :results, :action => :body

  map.datafiles 'datafiles/*path', :controller => :uploads, :action => :datafiles

  map.resources :uploads,
    :member => {:download => :get},
    :collection => {
        :mvdir => :get,
        :download_dir => :get
    }

  map.datafiles 'datafiles/*path', :controller => :uploads, :action => :datafiles

  map.resource :user_session
  map.login 'login', :controller => :user_sessions, :action => :new
  map.logout 'logout', :controller => :user_sessions, :action => :destroy

  map.resource :account, :controller => :users
  map.resources :users

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
