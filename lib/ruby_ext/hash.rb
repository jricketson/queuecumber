unless Hash.instance_methods.include?(:except)
  class Hash
    def except(*kk)
      each_with_object({}) { |(k, v), h| h[k] = v unless kk.include?(k) }
    end
  end
end
