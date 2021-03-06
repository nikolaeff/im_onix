require 'onix/price'

module ONIX

  class MarketDate < Subset
    attr_accessor :role, :date
    def parse(n)
      n.children.each do |t|
        case t.name
          when "MarketDateRole"
            @role = MarketDateRole.from_code(t.text)
          when "Date"
            @date=OnixDate.from_xml(t)
        end
      end
    end
  end

  class Market < Subset
    attr_accessor :territory

    def parse(n)
      n.children.each do |t|
        case t.name
          when "Territory"
            @territory=Territory.from_xml(t)
        end
      end
    end
  end

  class MarketPublishingDetail < Subset
    attr_accessor :publisher_representatives, :market_dates

    def initialize
      @publisher_representatives=[]
      @market_dates = []
    end

    def availability_date
      av=@market_dates.select{|sd| sd.role.human=="PublicationDate" || sd.role.human=="EmbargoDate"}.first
      if av
        av.date.date
      else
        nil
      end
    end

    def parse(n)
      @publisher_representatives=Agent.parse_entities(n, "./PublisherRepresentative")
      n.children.each do |t|
        case t.name
          when "MarketDate"
            @market_dates << MarketDate.from_xml(t)
        end
      end
    end

  end

  class SupplyDate < Subset
    attr_accessor :role, :date
    def parse(n)
      n.children.each do |t|
        case t.name
          when "SupplyDateRole"
            @role = SupplyDateRole.from_code(t.text)
          when "Date"
            @date = OnixDate.from_xml(t)
        end
      end
    end
  end

  class SupplyDetail < Subset
    attr_accessor :availability, :suppliers, :supply_dates, :prices

    def initialize
      @suppliers=[]
      @supply_dates=[]
      @prices=[]
    end

    def distributors
      @suppliers.select{|s| s.role.human=~/Distributor/}.uniq
    end

    def available?
      ["Available","InStock","ToOrder","Pod"].include?(@availability.human)
    end

    def sold_separately?
      @availability.human!="NotSoldSeparately"
    end

    def availability_date
      av=@supply_dates.select{|sd| sd.role.human=="ExpectedAvailabilityDate" || sd.role.human=="EmbargoDate"}.first
      if av
        av.date.date
      else
        nil
      end
    end

    def parse(n)
      @suppliers = Supplier.parse_entities(n, "./Supplier")

      n.children.each do |t|
        case t.name
          when "ProductAvailability"
            @availability=ProductAvailability.from_code(t.text)
          when "SupplyDate"
            @supply_dates << SupplyDate.from_xml(t)
          when "Price"
            @prices << Price.from_xml(t)
        end
      end
    end
  end

  class ProductSupply < Subset
    attr_accessor :supply_details, :markets, :market_publishing_detail

    def initialize
      @supply_details=[]
      @markets=[]
    end

    def distributors
      @supply_details.map{|sd| sd.distributors}.flatten.uniq{|d| d.name}
    end

    def available_supply_details
      @supply_details.select{|sd| sd.available?}
    end

    def unavailable_supply_details
      @supply_details.delete_if{|sd| sd.available?}
    end

    def available?
      self.available_supply_details.length > 0
    end

    def parse(n)
      n.children.each do |t|
        case t.name
          when "SupplyDetail"
            @supply_details << SupplyDetail.from_xml(t)
          when "Market"
            @markets << Market.from_xml(t)
          when "MarketPublishingDetail"
            @market_publishing_detail = MarketPublishingDetail.from_xml(t)
        end
      end
    end
  end

end