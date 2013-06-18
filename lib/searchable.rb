module Searchable
  def self.included(base)
    def base.searchable_on(*args)
      @searchable_attrs = args
    end

    def base.catalog_search(query)
      if query.blank? # if the string is blank, return all
        active
      else # in all other cases, search using the query text
        results = []
        query.split.each do |q|
          query_results = []
          @searchable_attrs.each do |attribute|
            query_results << active.where("#{attribute} LIKE :query", {:query => "%#{q}%"})
          end
          query_results.flatten!
          results << query_results
        end
        # take the intersection of the results for each word
        # i.e. choose results matching all terms
        results.inject(:&)
      end
    end
  end
end