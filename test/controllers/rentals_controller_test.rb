require "test_helper"

describe RentalsController do
  describe "checkout" do
    it "will create a new instance of a rental and return an id" do
      movie = movies(:movie1)
      customer = customers(:customer1)
      rental_data = {
        rental: {
          movie_id: movie.id,
          customer_id: customer.id,
        }
      }

      expect {
        post rental_checkout_path, params: rental_data
      }.must_differ "Rental.count", 1
      
      body = JSON.parse(response.body)
      expect(body.keys).must_include "id"
      must_respond_with :ok
    end

    it "will not create a rental with missing attributes" do
      customer = customers(:customer1)
      rental_data = {
        rental: {
          movie_id: nil,
          customer_id: customer.id,
        }
      }

      expect {
        post rental_checkout_path, params: rental_data
      }.wont_change "Rental.count"

      must_respond_with :bad_request
      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)

      expect(body).must_be_kind_of Hash
      expect(body["errors"].keys).must_include "movie"
    end

    it "won't create a rental for a movie with 0 inventory" do
      movie = Movie.create(
        title: "title",
        overview: "Description", 
        release_date: Time.new(2018, 1, 1) ,
        inventory: 0,
      )
      customer = customers(:customer1)
      rental_data = {
        rental: {
          movie_id: movie.id,
          customer_id: customer.id,
        }
      }

      expect {
        post rental_checkout_path, params: rental_data
      }.wont_change "Rental.count"

      must_respond_with :bad_request
      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body).must_be_kind_of Hash
      expect(body["errors"]).must_include "movie"
    end
  end

  describe "checkin" do
    it "will return the checked in rental's id and status of ok" do
      movie = movies(:movie1)
      customer = customers(:customer1)
      rental = Rental.create!(movie: movie, customer: customer, checkout_date: Time.now, due_date: Time.now + 7)

      rental_data = {id: rental.id}

      post rental_checkin_path, params: rental_data
      body = JSON.parse(response.body)
      expect(body.keys).must_include "id"
      must_respond_with :ok
    end

    it "will return a status of not_found if given invalid rental id" do
      rental_data = {id: -1}

      post rental_checkin_path, params: rental_data
      must_respond_with :not_found
      expect(response.header['Content-Type']).must_include 'json'
      body = JSON.parse(response.body)
      expect(body).must_be_kind_of Hash
      expect(body["errors"]).must_include "not found"
    end
  end

end

