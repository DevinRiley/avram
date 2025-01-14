require "./validations/**"

module Avram::Validations
  private def validate_required(*attributes, message = "is required")
    attributes.each do |attribute|
      if attribute.value.blank? && attribute.value != false
        attribute.add_error message
      end
    end
  end

  private def validate_acceptance_of(attribute : Attribute(Bool?), message = "must be accepted")
    if attribute.value != true
      attribute.add_error message
    end
  end

  private def validate_confirmation_of(attribute, with confirmation_attribute, message = "must match")
    if attribute.value != confirmation_attribute.value
      confirmation_attribute.add_error message
    end
  end

  private def validate_inclusion_of(attribute, in allowed_values, message = "is invalid")
    if !allowed_values.includes? attribute.value
      attribute.add_error message
    end
  end

  private def validate_size_of(attribute, *, is exact_size, message = "is invalid")
    if attribute.value.to_s.size != exact_size
      attribute.add_error message
    end
  end

  private def validate_size_of(attribute, min = nil, max = nil)
    if !min.nil? && !max.nil? && min > max
      raise ImpossibleValidation.new(attribute: attribute.name, message: "size greater than #{min} but less than #{max}")
    end

    size = attribute.value.to_s.size

    if !min.nil? && size < min
      attribute.add_error "is too short"
    end

    if !max.nil? && size > max
      attribute.add_error "is too long"
    end
  end

  private def validate_uniqueness_of(
    attribute : Avram::Attribute,
    query : Avram::Criteria,
    message : String = "is already taken"
  )
    attribute.value.try do |value|
      if query.eq(value).first?
        attribute.add_error message
      end
    end
  end

  private def validate_uniqueness_of(
    attribute : Avram::Attribute,
    message : String = "is already taken"
  )
    attribute.value.try do |value|
      if build_validation_query(attribute.name, attribute.value).first?
        attribute.add_error message
      end
    end
  end

  # Must be included in the macro to get access to the generic T class
  # in forms that save to the database.
  #
  # VirtualOperations will also have access to this, but will fail if you try to use
  # if because there is no T (model class).
  macro included
    private def build_validation_query(column_name, value) : T::BaseQuery
      query = T::BaseQuery.new.where(column_name, value)
      record.try(&.id).try do |id|
        query = query.id.not.eq(id)
      end
      query
    end
  end
end
