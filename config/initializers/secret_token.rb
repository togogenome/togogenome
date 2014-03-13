# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
TogoGenome::Application.config.secret_token = ENV['SECRET_TOKEN'] || '5932e80a7811e61ac3979e2a3b38e721d55b443e95ea5b7998b6a8330335fe25db3b3d7f34b27d38c7832bd3d2f786fb9cebbc1bb11533b4577d451c2753a991'
