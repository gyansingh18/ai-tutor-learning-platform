Rails.application.routes.draw do
  # Devise routes
  devise_for :users

  # Root route
  root "home#index"

  # Main app routes
  get "home/index"

  # AJAX routes for dropdowns (must come before RESTful routes)
  get "grades/:grade_id/subjects", to: "api/grades#subjects"
  get "grades/:grade_id/subjects/:subject_id/chapters", to: "api/subjects#chapters"

  # Grade routes
  resources :grades, only: [:index, :show] do
    resources :subjects, only: [:index, :show] do
      resources :chapters, only: [:index, :show] do
        resources :questions, only: [:index, :show, :new, :create]
      end
    end
  end

  # Questions and answers
  resources :questions, only: [:index, :show, :new, :create] do
    resources :answers, only: [:create]
  end

  # User profile
  get "profile", to: "users#show"
  get "profile/edit", to: "users#edit"
  patch "profile", to: "users#update"
  get "history", to: "questions#index"

  # Chat routes
  get "chat/:chapter_id", to: "chat#show", as: :chat
  post "chat/:chapter_id", to: "chat#create"
  get "chat", to: "chat#index", as: :chats

  # Learning routes (interactive learning environment)
  get "learning/:chapter_id", to: "learning#index", as: :learning
  get "learning/:chapter_id/task/:task_id", to: "learning#show_task", as: :learning_task
  post "learning/:chapter_id/task/:task_id/submit", to: "learning#submit_answer", as: :submit_task_answer
  get "learning/:chapter_id/task/:task_id/next", to: "learning#next_task", as: :next_task
  get "learning/:chapter_id/task/:task_id/previous", to: "learning#previous_task", as: :previous_task
  get "learning/:chapter_id/review", to: "learning#review", as: :chapter_review

  # Admin routes
  get "admin", to: redirect("/admin/dashboard")

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :pdf_materials, except: [:edit, :update]
    resources :users, only: [:index, :show]
    resources :chapters, only: [:index, :new, :create, :edit, :update, :destroy] do
      member do
        post :generate_tasks
      end
      resources :tasks, except: [:show]
    end
  end

  # API routes for AJAX
  namespace :api do
    resources :chapters, only: [:show] do
      member do
        get "explanation"
      end
    end
    resources :questions, only: [:create] do
      member do
        post "answer"
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
