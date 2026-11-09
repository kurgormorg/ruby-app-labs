# Explicit whitelist using Rails' built-in ActiveModel JSON serialization.
class ApplicationSerializer
  def initialize(record)
    @record = record
  end

  def as_json(*)
    @record.serializable_hash(only: self.class::ATTRIBUTES)
  end
end
