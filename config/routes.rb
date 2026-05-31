Rails.application.routes.draw do
  root "translation_batches#index"

  resources :translation_batches, only: [ :index, :new, :create, :show ] do
    resources :translation_jobs, only: [ :show ], shallow: true
  end
end
