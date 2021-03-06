require 'facebook/messenger'
require 'httparty'
require 'json'  
require_relative './subscription_template'
require_relative '../facebookBot/bot'
require_relative '../facebookBot/strings'
require_relative './subscription_strings'
require_relative '../models/user'

# @author Balaji
class SubscriptionClass

  # @param id [Integer] The receiver's Facebook user ID.
  # @return [nil]
  # To save user subscription information in the database table.
  #
  def save_user_profile(id)
    puts "Started save_user_profile "
    user = User.find_by_facebook_userid(id)
    if user == nil then
      user = User.new 
    end
    user.facebook_userid = id
    begin
      profile_details = MessengerBot.get_profile(id)
      user.locale = (profile_details["locale"] == nil)? "en" : profile_details["locale"]
    rescue
      # Setting en as default locale value of the user
      user.locale = "en"
    end
    user.featured_article_subscription = true
    user.image_of_the_day_subscription = true
    user.on_this_day_subscription = true
    user.news_subscription = true
    user.save
    puts "User subscription info saved"
  end

  # @param id [Integer] The receiver's Facebook user ID.
  # @return [nil]
  # Method to handle subscriptions
  #
  def show_subscriptions(id)
    language = MessengerBot.get_language(id)
    language = "en" unless MessengerBot::SUPPORTED_LANGUAGE.include?(language)
    user = User.find_by_facebook_userid(id)
    if user != nil then

      message_option = SUBSCRIPTION_MESSAGE_OPTION
      message_option[:recipient][:id] = id
      message_option[:message][:attachment][:payload][:elements][0][:title] = MessengerBot::FEATURED_ARTICLE_MESSAGE["#{language}"]
      message_option[:message][:attachment][:payload][:elements][1][:title] = MessengerBot::IMAGE_OF_THE_DAY_MESSAGE["#{language}"]
      message_option[:message][:attachment][:payload][:elements][2][:title] = MessengerBot::NEWS_MESSAGE["#{language}"]
      message_option[:message][:attachment][:payload][:elements][3][:title] = MessengerBot::ON_THIS_DAY_MESSAGE["#{language}"]

      if user.featured_article_subscription != true then
        message_option[:message][:attachment][:payload][:elements][0][:subtitle] = UNSUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][0][:buttons][0][:title] = SUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][0][:buttons][0][:payload] = "SUBSCRIBE_FEATURED_ARTICLE"
      else
        message_option[:message][:attachment][:payload][:elements][0][:subtitle] = SUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][0][:buttons][0][:title] = UNSUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][0][:buttons][0][:payload] = "UNSUBSCRIBE_FEATURED_ARTICLE"
      end
      
      if user.image_of_the_day_subscription != true then
        message_option[:message][:attachment][:payload][:elements][1][:subtitle] = UNSUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][1][:buttons][0][:title] = SUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][1][:buttons][0][:payload] = "SUBSCRIBE_IMAGE_OF_THE_DAY"
      else
        message_option[:message][:attachment][:payload][:elements][1][:subtitle] = SUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][1][:buttons][0][:title] = UNSUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][1][:buttons][0][:payload] = "UNSUBSCRIBE_IMAGE_OF_THE_DAY"
      end

      if user.news_subscription != true then
        message_option[:message][:attachment][:payload][:elements][2][:subtitle] = UNSUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][2][:buttons][0][:title] = SUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][2][:buttons][0][:payload] = "SUBSCRIBE_NEWS"
      else
        message_option[:message][:attachment][:payload][:elements][2][:subtitle] = SUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][2][:buttons][0][:title] = UNSUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][2][:buttons][0][:payload] = "UNSUBSCRIBE_NEWS"
      end

      if user.on_this_day_subscription != true then
        message_option[:message][:attachment][:payload][:elements][3][:subtitle] = UNSUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][3][:buttons][0][:title] = SUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][3][:buttons][0][:payload] = "SUBSCRIBE_ON_THIS_DAY"
      else
        message_option[:message][:attachment][:payload][:elements][3][:subtitle] = SUBSCRIBED_SUBTITLE_TEXT["#{language}"]
        message_option[:message][:attachment][:payload][:elements][3][:buttons][0][:title] = UNSUBSCRIBE_BUTTON["#{language}"]
        message_option[:message][:attachment][:payload][:elements][3][:buttons][0][:payload] = "UNSUBSCRIBE_ON_THIS_DAY"
      end
      res = HTTParty.post(FB_MESSAGE, headers: HEADER, body: message_option.to_json)
    else
      # Registering the user
      puts "User row not found in DB.\nInserting new user row..."
      SubscriptionClass.new.save_user_profile(id)
      show_subscriptions(id)
    end
  end

  # @param id [Integer] The receiver's Facebook user ID.
  # @param category [String] This denotes the category in which the user wants to subscribe.
  # @return [nil]
  # This method used to subscribe for daily Featured articles.
  #
  def subscribe(id,category)
    language = MessengerBot.get_language(id)
    language = "en" unless MessengerBot::SUPPORTED_LANGUAGE.include?(language)
    user = User.find_by_facebook_userid(id)
    puts "Subscribing #{category}"
    case category
    when "FEATURED_ARTICLE"
      user.update_attributes( :featured_article_subscription => true)
      MessengerBot.say(id,SUBSCRIBED_FEATURED_ARTICLE_TEXT["#{language}"])
    when "IMAGE_OF_THE_DAY"
      user.update_attributes( :image_of_the_day_subscription => true)
      MessengerBot.say(id,SUBSCRIBED_IMAGE_OF_THE_DAY_TEXT["#{language}"])
    when "NEWS"
      user.update_attributes( :news_subscription => true)
      MessengerBot.say(id,SUBSCRIBED_NEWS_TEXT["#{language}"])
    when "ON_THIS_DAY"
      user.update_attributes( :on_this_day_subscription => true)
      MessengerBot.say(id,SUBSCRIBED_ON_THIS_DAY_TEXT["#{language}"])
    end
  end

  # @param id [Integer] The receiver's Facebook user ID.
  # @param category [String] This denotes the category that the user wants to unsubscribe.
  # @return [nil]
  # This method used to unsubscribe from daily Featured articles subscriptions.
  #
  def unsubscribe(id,category)
    language = MessengerBot.get_language(id)
    language = "en" unless MessengerBot::SUPPORTED_LANGUAGE.include?(language)
    user = User.find_by_facebook_userid(id)
    puts "Unsubscribing #{category}"
    case category
    when "FEATURED_ARTICLE"
      user.update_attributes( :featured_article_subscription => false)
      MessengerBot.say(id,UNSUBSCRIBED_FEATURED_ARTICLE_TEXT["#{language}"])
    when "IMAGE_OF_THE_DAY"
      user.update_attributes( :image_of_the_day_subscription => false)
      MessengerBot.say(id,UNSUBSCRIBED_IMAGE_OF_THE_DAY_TEXT["#{language}"])
    when "NEWS"
      user.update_attributes( :news_subscription => false)
      MessengerBot.say(id,UNSUBSCRIBED_NEWS_TEXT["#{language}"])
    when "ON_THIS_DAY"
      user.update_attributes( :on_this_day_subscription => false)
      MessengerBot.say(id,UNSUBSCRIBED_ON_THIS_DAY_TEXT["#{language}"])
    end
  end 


end