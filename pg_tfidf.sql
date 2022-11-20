SELECT tf_idf_stemmed.groupid,
       tf_idf_stemmed.stemmed_word[1] AS word,
       tf_idf_stemmed.tf_idf,
       tf_idf_stemmed.tf,
       tf_idf_stemmed.df,
       tf_idf_stemmed.idf
FROM ( SELECT tf_idf.groupid,
              tf_idf.word,
              ts_lexize('english_stem'::regdictionary, tf_idf.word) AS stemmed_word,
              tf_idf.tf,
              tf_idf.df,
              tf_idf.idf,
              tf_idf.tf_idf
       FROM ( WITH docs_cte AS (
           SELECT docs_cleaned.groupid,
                  regexp_split_to_table(docs_cleaned.oedesc, '[ .,/#!$%^&*;:{}=_`~()-]'::text) AS word
           FROM docs.docs_cleaned
       )
              SELECT t6.groupid,
                     t6.word,
                     t6.tf,
                     t6.df,
                     t6.idf,
                     ((t6.tf)::double precision * t6.idf) AS tf_idf
              FROM ( SELECT t5.groupid,
                            t5.word,
                            t5.tf,
                            t5.df,
                            ((t5.tf)::double precision / log((((( SELECT count(*) AS cnt
                                                                  FROM ( SELECT docs_cte.groupid,
                                                                                docs_cte.word
                                                                         FROM docs_cte) s1
                                                                  WHERE (btrim(s1.word) <> ''::text)) / t5.df) + 1))::double precision)) AS idf
                     FROM ( SELECT t3.groupid,
                                   t3.word,
                                   ((t3.word_cnt)::numeric / t3.total_word_count) AS tf,
                                   t4.word_cnt AS df
                            FROM (( SELECT t2.groupid,
                                           t2.word,
                                           t2.word_cnt,
                                           sum(t2.word_cnt) OVER (PARTITION BY t2.groupid) AS total_word_count
                                    FROM ( SELECT t1.groupid,
                                                  t1.word,
                                                  count(*) AS word_cnt
                                           FROM ( SELECT docs_cte.groupid,
                                                         docs_cte.word
                                                  FROM docs_cte) t1
                                           WHERE (btrim(t1.word) <> ''::text)
                                           GROUP BY t1.groupid, t1.word) t2) t3
                                     JOIN ( SELECT t1.word,
                                                   count(*) AS word_cnt
                                            FROM ( SELECT docs_cte.groupid,
                                                          docs_cte.word
                                                   FROM docs_cte) t1
                                            WHERE (btrim(t1.word) <> ''::text)
                                            GROUP BY t1.word) t4 ON ((t3.word = t4.word)))) t5) t6) tf_idf) tf_idf_stemmed
WHERE ((tf_idf_stemmed.stemmed_word[1] IS NOT NULL) AND (NOT (btrim(tf_idf_stemmed.stemmed_word[1]) ~ '[^[:alpha:]]'::text)))