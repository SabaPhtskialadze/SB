library(shiny)
library(dplyr)
library(tidyr)
library(tidytext)
library(ggplot2)
library(textstem)
library(wordcloud)
library(RColorBrewer)

load(file = "videogames_50threads.rda")
str(threads_df)

# tidy table: text column to unite thread's title, text, and comments
threads_tbl <- as_tibble(threads_df) %>%
  unite(title, text, text_comments, col = "text", sep = " ")

# tokenization:
# unnest_tokens removes punctuation, converts text to lower case
threads_words <- threads_tbl %>%
  unnest_tokens(word, text) %>%
  # omit most rare words: keep those occurring more than 10 times
  group_by(word) %>%
  filter(n() > 400) %>%
  ungroup()

# remove stop words (corpus available within tidytext)
threads_words_clean <- threads_words %>%
  filter(!word %in% stop_words$word,
         !word %in% c("1","2","3","4")) %>%
  filter(!is.na(word)) %>%
  mutate(word = lemmatize_words(word)) %>%
  filter(!word %in% c("game","play"))

# term frequency (tf)
threads_words_count <- threads_words_clean %>% count(word, sort = TRUE)

threads_words_tf_idf <- threads_words_clean %>%
  count(url, word, sort = TRUE) %>%
  bind_tf_idf(word, url, n) %>%
  group_by(word) %>% 
  summarise(tf_idf_sum = sum(tf_idf)) %>%
  arrange(desc(tf_idf_sum))

threads_bigram <- threads_tbl %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>%
  filter(!word1 %in% stop_words$word,
         !word2 %in% stop_words$word,
         !is.na(word1)) %>%
  count(word1, word2, sort = TRUE)

threads_trigram <- threads_tbl %>%
  unnest_tokens(trigram, text, token = "ngrams", n = 3) %>%
  separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%
  filter(!word1 %in% stop_words$word,
         !word2 %in% stop_words$word,
         !word3 %in% stop_words$word,  
         !is.na(word1)) %>%
  count(word1, word2, word3, sort = TRUE)


shinyServer(function(input, output, session) {
  
  output$bigramGraph <- renderPlot({

    
    # plot terms with frequencies exceeding a threshold
    nmin <- input$minFreq
    threads_words_count %>%
      filter(n > nmin) %>%
      mutate(word = reorder(word, n)) %>%
      ggplot(aes(word, n)) +
      geom_col(show.legend = FALSE, fill = "#2E0854") +
      xlab(NULL) +
      scale_y_continuous(expand = c(0, 0)) +
      coord_flip() +
      theme_classic(base_size = 12) +
      labs(title="Word frequency", subtitle=paste("n >", nmin)) +
      theme(
        plot.title = element_text(lineheight = .8, face = "bold", color = "black"),
        plot.subtitle = element_text(color = "black"),
        axis.title = element_text(color = "black"),
        axis.text = element_text(color = "black", size=17),
        axis.line = element_line(color = "black"),
        axis.ticks = element_line(color = "black"),
        panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white")
      )
  })
  
  output$wordcloud <- renderPlot({
    wordcloud(threads_words_count$word, threads_words_count$n, max.words = 50,
              colors=brewer.pal(3, "Dark2"), scale=c(1, 1))
  })
  
  output$Tf <- renderPlot({
    # highest tf-idf terms across all threads
    threads_words_tf_idf %>%
      top_n(input$numTopTerms, tf_idf_sum) %>% 
      ggplot(aes(reorder(word, tf_idf_sum), tf_idf_sum)) +
      scale_y_continuous(expand = c(0, 0)) +
      geom_col(show.legend = FALSE,fill = "#2E0854") +
      labs(x = NULL, y = "tf-idf") +
      coord_flip() +
      theme_classic(base_size = 12) +
      labs(title="Term frequency and inverse document frequency (tf-idf)", 
           subtitle="Top words overall",
           x= NULL, 
           y= "tf-idf") +
      theme(
        plot.title = element_text(lineheight = .8, face = "bold", color = "black"),
        plot.subtitle = element_text(color = "black"),
        axis.title = element_text(color = "black"),
        axis.text = element_text(color = "black", size=17),
        axis.line = element_line(color = "black"),
        axis.ticks = element_line(color = "black"),
        panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white")
      )
  })
  
  output$wordcloudtf <- renderPlot({
    wordcloud(threads_words_tf_idf$word, threads_words_tf_idf$tf_idf_sum, max.words = 50,
              colors=brewer.pal(3, "Dark2"), scale=c(1, 1))
  })
  
  output$Bigram <- renderPlot({
    
    threads_bigram %>%
      top_n(input$numTopTerms, n) %>% 
      ggplot(aes(reorder(paste(word1, word2), n), n)) +
      scale_y_continuous(expand = c(0, 0)) +
      geom_col(show.legend = FALSE, fill = "#2E0854") +
      coord_flip() +
      theme_classic(base_size = 12) +
      labs(title="Bigram count", 
           subtitle="Total counts in all documents",
           x= NULL, 
           y= "count") +
      theme(
        plot.title = element_text(lineheight = .8, face = "bold", color = "black"),
        plot.subtitle = element_text(color = "black"),
        axis.title = element_text(color = "black"),
        axis.text = element_text(color = "black", size=17),
        axis.line = element_line(color = "black"),
        axis.ticks = element_line(color = "black"),
        panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white")
      )
    
  })
  
  output$Trigrams <- renderPlot({
    threads_trigram %>%
      top_n(input$numTopTerms, n) %>% 
      ggplot(aes(reorder(paste(word1, word2, word3), n), n)) +
      scale_y_continuous(expand = c(0, 0)) +
      geom_col(show.legend = FALSE, fill = "#2E0854") +
      coord_flip() +
      theme_classic(base_size = 12) +
      labs(title="Trigram count", 
           subtitle="Total counts in all documents",
           x= NULL, 
           y= "count") +
      theme(
        plot.title = element_text(lineheight = .8, face = "bold", color = "black"),
        plot.subtitle = element_text(color = "black"),
        axis.title = element_text(color = "black"),
        axis.text = element_text(color = "black", size=17),
        axis.line = element_line(color = "black"),
        axis.ticks = element_line(color = "black"),
        panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white")
      )
  })
  
  observeEvent(input$aboutBtn, {
    showModal(modalDialog(
      title = "About This Application",
      HTML("
    <h4>About This Application</h4>
    <p>This Shiny dashboard provides an in-depth analysis of the 50 most popular threads on Reddit about video games, including comments and replies. The goal of this application is to offer insights into the most discussed topics, trends, and sentiments within the video game community.</p>
    
    <h4>Features:</h4>
    <ul>
      <li><b>Filters:</b> Adjust the frequency of bigrams and the number of top terms to customize the analysis.</li>
      <li><b>Word Frequency:</b> Visualize the frequency of words used in the discussions, helping to identify common themes and topics.</li>
      <li><b>Word Clouds:</b> Generate word clouds to see a graphical representation of the most frequent words and terms.</li>
      <li><b>N-Grams:</b> Analyze bi-grams and tri-grams to understand common word pairs and triplets in the discussions.</li>
    </ul>
    
    <h4>Data Source:</h4>
    <p>The data was parsed from the 50 hottest threads on Reddit related to video games, including all comments and replies. This comprehensive dataset provides a rich source of information for understanding community sentiments and popular discussion points.</p>
    
    <h4>Usage:</h4>
    <p>Use the filters on the sidebar to adjust the parameters and explore the visualizations in different tabs. The \"Reset Filters\" button allows you to revert to the default settings. The \"About\" button provides information about the application and its features.</p>
    
    <p>This dashboard aims to provide valuable insights into the video game community on Reddit, making it a useful tool for gamers, developers, and researchers alike.</p>
    "),
      easyClose = TRUE,
      footer = NULL
    ))
  })
  
  observeEvent(input$reset, {
    updateSliderInput(session, "minFreq", value = 450)
    updateSliderInput(session, "numTopTerms", value = 8)
  })
})