class Annotation
  # normalize annotations passed by an HTTP call
  def self.normalize!(annotations, prefix = nil)
    return "annotations must be a hash." unless annotations.class == Hash
    return "annotations must include a 'text'"  unless annotations[:text].present?

    if annotations[:sourcedb].present?
      annotations[:sourcedb] = 'PubMed' if annotations[:sourcedb].downcase == 'pubmed'
      annotations[:sourcedb] = 'PMC' if annotations[:sourcedb].downcase == 'pmc'
      annotations[:sourcedb] = 'FirstAuthor' if annotations[:sourcedb].downcase == 'firstauthor'
    end

    if annotations[:denotations].present?
      return "'denotations' must be an array." unless annotations[:denotations].class == Array
      annotations[:denotations].each{|d| d = d.symbolize_keys}

      annotations = Annotation.chain_spans(annotations)

      ids = annotations[:denotations].collect{|d| d[:id]}.compact
      idnum = 1

      annotations[:denotations].each do |a|
        return "a denotation must have a 'span' or a pair of 'begin' and 'end'." unless (a[:span].present? && a[:span][:begin].present? && a[:span][:end].present?) || (a[:begin].present? && a[:end].present?)
        return "a denotation must have an 'obj'." unless a[:obj].present?

        unless a.has_key? :id
          idnum += 1 until !ids.include?('T' + idnum.to_s)
          a[:id] = 'T' + idnum.to_s
          idnum += 1
        end
        a[:span] = {begin: a[:begin], end: a[:end]} if !a[:span].present? && a[:begin].present? && a[:end].present?

        a[:span][:begin] = a[:span][:begin].to_i if a[:span][:begin].is_a? String
        a[:span][:end]   = a[:span][:end].to_i   if a[:span][:end].is_a? String

        return "the begin offset must be between 0 and the length of the text: #{a}" if a[:span][:begin] < 0 || a[:span][:begin] > annotations[:text].length
        return "the end offset must be between 0 and the length of the text." if a[:span][:end] < 0 || a[:span][:end] > annotations[:text].length
        return "the begin offset must not be bigger than the end offset." if a[:span][:begin] > a[:span][:end]
      end
    end

    if annotations[:relations].present?
      return "'relations' must be an array." unless annotations[:relations].class == Array
      denotation_ids = annotations[:denotations].collect{|a| a[:id]}

      annotations[:relations].each{|a| a = a.symbolize_keys}

      ids = annotations[:relations].collect{|a| a[:id]}.compact
      idnum = 1

      annotations[:relations].each do |a|
        return "a relation must have 'subj', 'obj' and 'pred'." unless a[:subj].present? && a[:obj].present? && a[:pred].present?
        return "'subj' and 'obj' of a relation must reference to a denotation: [#{a}]." unless (denotation_ids.include? a[:subj]) && (denotation_ids.include? a[:obj])

        unless a.has_key? :id
          idnum += 1 until !ids.include?('R' + idnum.to_s)
          a[:id] = 'R' + idnum.to_s
          idnum += 1
        end
      end
    end

    if annotations[:modifications].present?
      return "'modifications' must be an array." unless annotations[:modifications].class == Array
      annotations[:modifications].each{|a| a = a.symbolize_keys}

      dr_ids = annotations[:denotations].collect{|a| a[:id]} + annotations[:relations].collect{|a| a[:id]}

      ids = annotations[:modifications].collect{|a| a[:id]}.compact
      idnum = 1

      annotations[:modifications].each do |a|
        return "a modification must have 'pred' and 'obj'." unless a[:pred].present? && a[:obj].present?
        return "'obj' of a modification must reference to a denotation or a relation: [#{a}]." unless dr_ids.include? a[:obj]

        unless a.has_key? :id
          idnum += 1 until !ids.include?('M' + idnum.to_s)
          a[:id] = 'M' + idnum.to_s
          idnum += 1
        end
      end
    end

    if prefix.present?
      annotations[:denotations].each {|a| a[:id] = prefix + '_' + a[:id]} if annotations[:denotations].present?
      annotations[:relations].each {|a| a[:id] = prefix + '_' + a[:id]; a[:subj] = prefix + '_' + a[:subj]; a[:obj] = prefix + '_' + a[:obj]} if annotations[:relations].present?
      annotations[:modifications].each {|a| a[:id] = prefix + '_' + a[:id]; a[:obj] = prefix + '_' + a[:obj]} if annotations[:modifications].present?
    end

    annotations
  end

  def self.chain_spans(annotations)
    r = annotations[:denotations].inject({denotations:[], chains:[]}) do |m, d|
      if (d[:span].class == Array) && (d[:span].length > 1)
        last = d[:span].length - 1
        d[:span].each_with_index do |s, i|
          obj = (i == last) ? d[:obj] : '_FRAGMENT'
          m[:denotations] << {id:d[:id] + "-#{i}", span:s, obj:obj}
          m[:chains] << {id:'C-' + d[:id] + "-#{i-1}", pred:'_lexicallyChainedTo', subj: d[:id] + "-#{i}", obj: d[:id] + "-#{i-1}"} if i > 0
        end
      else
        m[:denotations] << d
      end
      m
    end

    denotations = r[:denotations]
    chains = r[:chains]

    annotations[:denotations] = denotations
    unless chains.empty?
      annotations[:relations] ||=[]
      annotations[:relations] += chains
    end
    annotations
  end

  # to work on the hash representation of denotations
  # to assume that there is no bag representation to this method
  def self.align_denotations(denotations, str1, str2)
    return nil if denotations.nil?
    align = TextAlignment::TextAlignment.new(str1, str2, TextAlignment::MAPPINGS)
    align.transform_hdenotations(denotations).select{|a| a[:span][:begin].to_i <= a[:span][:end].to_i }
  end

  # TODO: when a span is specified, restrict the alignment within the span.
  def self.align_annotations(annotations, doc, span = nil)
    original_text = annotations[:text]
    annotations[:text] = doc
    if annotations[:denotations].present? && original_text != annotations[:text]
      num = annotations[:denotations].length
      annotations[:denotations] = align_denotations(annotations[:denotations], original_text, annotations[:text])
      return "Alignment failed. Text may be too much different." if annotations[:denotations].length < num
      annotations[:denotations].each{|d| return "Alignment failed. Text may be too much different." if d[:span][:begin].nil? || d[:span][:end].nil?}
    end

    annotations.select{|k,v| v.present?}
  end

  def self.prepare_annotations_divs(annotations, divs)
    annotations_collection = []
    div_index = divs.collect{|d| [d[:divid], d]}.to_h
    divs_hash = divs.collect{|d| d.to_hash}
    fit_index = TextAlignment.find_divisions(annotations[:text], divs_hash)

    fit_index.each do |i|
      if i[0] >= 0
        ann = {sourcedb:annotations[:sourcedb], sourceid:annotations[:sourceid], divid:i[0]}
        idx = {}
        ann[:text] = annotations[:text][i[1][0] ... i[1][1]]
        if annotations[:denotations].present?
          ann[:denotations] = annotations[:denotations]
                               .select{|a| a[:span][:begin] >= i[1][0] && a[:span][:end] <= i[1][1]}
                              .collect{|a| n = a.dup; n[:span] = a[:span].dup; n}
                                 .each{|a| a[:span][:begin] -= i[1][0]; a[:span][:end] -= i[1][0]}
          ann[:denotations].each{|a| idx[a[:id]] = true}
        end
        if annotations[:relations].present?
          ann[:relations] = annotations[:relations].select{|a| idx[a[:subj]] && idx[a[:obj]]}
          ann[:relations].each{|a| idx[a[:id]] = true}
        end
        if annotations[:modifications].present?
          ann[:modifications] = annotations[:modifications].select{|a| idx[a[:obj]]}
          ann[:modifications].each{|a| idx[a[:id]] = true}
        end
        annotations_collection << align_annotations(ann, div_index[i[0]][:text])
      end
    end
    # {div_index: fit_index}
    annotations_collection
  end
end
