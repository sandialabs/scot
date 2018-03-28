Utils = require '../utils/utils'
{Result} = require '../utils/result'

class NaiveBayes
    # thresholds should be an object whose keys are categories, and
    # values are to be used for numeric thresholds during
    # classification
    constructor: (@picker=(x)->x) ->
        @model = {}
        @total_samples = 0
        @total_words = 0
        @global_freq = {}

    total_samples: () -> (Object.keys @global_freq).length
    
    sample: (category,wordlist) ->
        @model[category] ?= 
            frequencies: {}
            samples: 0
            words: 0
        @model[category].samples += 1
        @thresholds[category] ?= 0.0005
        for word in wordlist
            @model[category].frequencies[word] ?= 0
            @model[category].frequencies[word] += 1
            @model[category].words += 1
            @global_freq[word] ?= 0
            @global_freq[word] += 1
        @total_samples += 1
        @total_words = (Object.keys @global_freq).length
        
    train: (samples) ->
        for own category of samples
            for sample in samples[category]
                @sample category,sample

    p_word_given_category: (word, category) ->
        freq = ((@model[category].frequencies[word]) or 0) + 1
        freq / (@model[category].words+@total_words)

    p_word: (word) ->
        ((@global_freq[word] or 0)+1)/@total_words

    p_sample: (wordlist) ->
        ((@p_word w) for w in wordlist).reduce (a,b)->a*b

    p_sample_given_category: (wordlist,category) ->
        ((@p_word_given_category word,category) for word in wordlist).reduce (a,b)->a*b
        
    p_category: (category) ->
        (@model[category].samples)/@total_samples
        
    p_category_given_word: (word,category) ->
        (@p_word_given_category word,category) * (@p_category category) / (@p_word word)

    measure: (wordlist) ->
        probabilities = {}
        psample = @p_sample wordlist
        for own category of @model
            probabilities[category] = \
                (@p_sample_given_category wordlist,category)*((@p_category category)/psample)
        probabilities

    normalize: (probabilities) ->
        total = 0
        for own cat,prob of probabilities
            total += prob
        for own cat of probabilities
            probabilities[cat] /= total
        probabilities
    
    classify: (wordlist) ->
        p = @measure wordlist
        max_p = 0
        best = {}
        for own cat,prob of p
             if prob > max_p
                 best.category = cat
                 best.probability = prob
                 max_p = prob
        if best.probability >= @thresholds[best.category]
            best
        else
            undefined

    classify_all: (samples) ->
        result = {}
        for sample in samples
            cat = @classify sample
            if cat
                result[cat.category] ?= []
                result[cat.category].push [cat.probability,sample]
            else
                result['_'].push [0,sample]
        result
        
    @commands:
        help__nbayes: () -> """
            nbayes [thresholds]

            Create a new naive bayes classifier based on the
            categories and samples that come in on the data
            pipeline. This command expects the data to be formatted as
            an object whose keys are categories, and values are lists
            of wordlist samples for that category.

            The result will be a naive bayes classifier that you can
            then use to classify unknown samples based on the learned
            model.

            Examples:
                $ emails \\ transpose \\ nbayes (s)->uniq (sort (String.words s.subject)) \\ store emailcategories
                <Bayes classifier>

                $ new_emails \\ classify emailcategories
                {
                    spam: [list of spam matches]
                    ham: [list of non-spam]
                    _: [list of ambiguous matches]
                }
            """

        nbayes: (argv,data,ctx) ->
            (Utils.parsefunction (argv.join ' '),ctx)
                .map (picker) ->
                    nb = new NaiveBayes picker
                    nb.train data
                    nb
                .err_and_then () ->
                    nb = new NaiveBayes
                    nb.train data
                    Result.wrap nb
                   
        help__classify: () -> """
            classify <naivebayes classifier> [sampler]

            Use the classifier given on the command line to determine
            a most-likely match for each element in the input set. The
            classifier is created using the nbayes command.

            This command expects samples to be lists of words. If your
            data is not in that shape, you can provide a function on
            the command line that will transform your data into a word
            list for the classifier to use. This function is optional,
            but the classifier will fail if its data is not a flat
            list of words for each sample.

            Example:
                $ emails \\ classify nbc (msg)->Strings.nohtml (Strings.words msg.MAILSUBJECT)
                {
                    cat1: [list of emails]
                    cat2: [list of emails]
                    ...
                    _: [list of failed matches]
                }
            """

        classify: (argv,data,ctx) ->
            Result.err "Not implemented!"
            
        
module.exports = NaiveBayes
