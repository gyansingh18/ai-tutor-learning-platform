class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @grades = Grade.ordered
  end
end
