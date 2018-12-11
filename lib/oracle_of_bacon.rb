require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri

  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    # YOUR CODE HERE
    @errors.add(@from, @to, message: "Shouldn't be the same") if @from == @to
  end

  def initialize(api_key='')
    # your code here
    @api_key = api_key
    @errors = ActiveModel::Errors.new(self)
    @from = "Kevin Bacon"
    @to = "Kevin Bacon"
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      # your code here
      raise NetworkError.new(e.message)
    end
    # your code here: create the OracleOfBacon::Response object
    OracleOfBacon::Response.new(xml)
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments

    #params =  "p=fake_key&a=#{CGI.escape(@from)}&b=#{CGI.escape(@to)}"
    params =  "p=#{@api_key}&a=#{CGI.escape(@from)}&b=#{CGI.escape(@to)}"
    @uri = "http://oracleofbacon.org/cgi-bin/xml?#{params}"

  end

  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if ! @doc.xpath('/error').empty?
        parse_error_response
      # your code here: 'elsif' clauses to handle other responses
      # for responses not matching the 3 basic types, the Response
      # object should have type 'unknown' and data 'unknown response'
      elsif ! @doc.xpath('/link').empty?
        @type = :graph
        parse_xml_xpath('/link/*')

      elsif ! @doc.xpath('/spellcheck').empty?
        @type = :spellcheck
        parse_xml_xpath('/spellcheck/*')

      else
        @type = :unknown
        @data = "unknown"
      end


    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end

    def parse_xml_xpath(xpath)
      @data = []
      @doc.xpath(xpath).each do |element|
        @data.push(element.text)
      end
    end
  end
end

