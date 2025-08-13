class DrawingChannel < ApplicationCable::Channel
  def subscribed
  end

  def unsubscribed
    remove_user_from_room
  end

  def receive(data)
    parsed_data = data.is_a?(String) ? JSON.parse(data) : data
    
    case parsed_data["action"]
    when "join_canvas"
      join_canvas(parsed_data)
    when "leave_room"
      leave_room
    else
      return unless @room_code
      ActionCable.server.broadcast("drawing_room_#{@room_code}", parsed_data.merge({
        "timestamp" => Time.current.iso8601
      }))
    end
  end

  def join_canvas(data)
    @username = data["username"]
    @room_code = data["room_code"]
    
    if data["mode"] == "join"
      existing_users = online_users_for_room
      if existing_users.empty?
        transmit({
          "type" => "error",
          "message" => "Room #{@room_code} does not exist"
        })
        return
      end
    end
    
    stream_from "drawing_room_#{@room_code}"
    add_user_to_room
    
    transmit({
      "type" => "room_joined",
      "room_code" => @room_code,
      "users" => online_users_for_room.to_a,
      "timestamp" => Time.current.iso8601
    })
    
    ActionCable.server.broadcast("drawing_room_#{@room_code}", {
      "type" => "user_joined",
      "user" => data["username"],
      "room_code" => @room_code,
      "timestamp" => Time.current.iso8601
    })
  end

  def leave_room
    remove_user_from_room
    
    transmit({
      "type" => "room_left",
      "timestamp" => Time.current.iso8601
    })
  end

  private

  def add_user_to_room
    return unless @username && @room_code
    
    room_users = online_users_for_room
    room_users.add(@username)
    Rails.cache.write("online_users_#{@room_code}", room_users.to_a, expires_in: 1.hour)
    
    broadcast_user_list
  end

  def remove_user_from_room
    return unless @username && @room_code
    
    users = online_users_for_room
    users.delete(@username)
    
    if users.empty?
      Rails.cache.delete("online_users_#{@room_code}")
    else
      Rails.cache.write("online_users_#{@room_code}", users.to_a, expires_in: 1.hour)
      
      ActionCable.server.broadcast("drawing_room_#{@room_code}", {
        "type" => "user_left",
        "user" => @username,
        "room_code" => @room_code,
        "timestamp" => Time.current.iso8601
      })
      
      broadcast_user_list
    end
  end

  def online_users_for_room
    Set.new(Rails.cache.read("online_users_#{@room_code}") || [])
  end

  def broadcast_user_list
    return unless @room_code
    
    ActionCable.server.broadcast("drawing_room_#{@room_code}", {
      "type" => "users_update",
      "users" => online_users_for_room.to_a,
      "room_code" => @room_code,
      "timestamp" => Time.current.iso8601
    })
  end
end