require 'messages/route_create_message'
require 'messages/routes_list_message'
require 'messages/route_show_message'
require 'messages/route_update_message'
require 'messages/route_update_destinations_message'
require 'actions/update_route_destinations'
require 'presenters/v3/route_presenter'
require 'presenters/v3/route_destinations_presenter'
require 'presenters/v3/paginated_list_presenter'
require 'actions/route_create'
require 'actions/route_delete'
require 'actions/route_update'
require 'fetchers/app_fetcher'
require 'fetchers/route_fetcher'

class UsersController < ApplicationController
  def create
    unauthorized! unless permission_queryer.can_write_globally?

    message = UserCreateMessage.new(hashed_params[:body])
    unprocessable!(message.errors.full_messages) unless message.valid?

    render status: :created, json: {}
  end


  private

  # def user_not_found!
  #   resource_not_found!(:user)
  # end

  # def unprocessable_destination!
  #   unprocessable!('Unable to unmap route from destination. Ensure the route has a destination with this guid.')
  # end

end
