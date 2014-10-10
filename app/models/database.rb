class Database
  class << self
    def all
      @@list ||= JSON.parse(Rails.root.join('public', 'dbmapping.json').read)['DBs']
    end

    def find(id)
      all[id]
    end
  end
end
