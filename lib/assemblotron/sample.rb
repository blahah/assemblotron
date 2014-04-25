require 'inline'

module Assemblotron

  # A subsampler for a pair of FASTQ read files.
  class Sample

    # Create a new Sample
    #
    # @param left [String] file path to the FASTQ file containing the
    #   left reads.
    # @param right [String] file path to the FASTQ file containing the
    #   right reads.
    # @return [Sample] the Sample.
    def initialize(left, right)
      @left = left
      @right = right
    end

    # C function to perform reservoir sampling of paired FASTQ
    # records.
    # 
    # This function was written in inlined C to give a speedup
    # of around 300x compared to native Ruby.
    #
    # @param n [Integer] the number of read pairs to sample.
    # @param seed [Integer] seed for the random number generator.
    # @param left [String] file path to the FASTQ file containing the
    #   left reads.
    # @param right [String] file path to the FASTQ file containing the
    #   right reads.
    # @param leftout [String] file path where left sample will be written.
    # @param rightout [String] file path where right sample will be written.
    inline :C do |builder|
    builder.add_compile_flags %q(-w)
    builder.include '<stdio.h>'
    builder.include '<strings.h>'
    builder.c <<SRC
      void subsampleC(VALUE n, VALUE seed, 
                      VALUE left, VALUE right, 
                      VALUE leftout, VALUE rightout) {
        char * filename_left;
        char * filename_right;
        char * outname_left;
        char * outname_right;
        char * line_l1 = NULL;
        char * line_l2 = NULL;
        char * line_l3 = NULL;
        char * line_l4 = NULL;
        char * line_r1 = NULL;
        char * line_r2 = NULL;
        char * line_r3 = NULL;
        char * line_r4 = NULL;
        size_t len = 0;
        ssize_t read_l;
        ssize_t read_r;
        unsigned nc,i,seedc;
        float a,r;
        unsigned long count;
        FILE *lfp;
        FILE *rfp;

        nc = NUM2INT(n);
        seedc = NUM2INT(seed);
        const char *res_l[nc];
        const char *res_r[nc];
 
        srand(seedc);
        filename_left = StringValueCStr(left);
        filename_right = StringValueCStr(right);
        outname_left = StringValueCStr(leftout);
        outname_right = StringValueCStr(rightout);

        lfp = fopen(filename_left, "r");
        rfp = fopen(filename_right, "r");

        if (lfp == NULL) {
          fprintf(stderr, "Cant open left read file for subsetting!\\n");
          exit(1);
        }
        if (rfp == NULL) {
          fprintf(stderr, "Cant open right read file for subsetting!\\n");
          exit(1);
        }

        count=1;
        while ((read_l = getline(&line_l1, &len, lfp)) != -1) {
          read_l += getline(&line_l2, &len, lfp);
          read_l += getline(&line_l3, &len, lfp);
          read_l += getline(&line_l4, &len, lfp);
          read_r =  getline(&line_r1, &len, rfp);
          read_r += getline(&line_r2, &len, rfp);
          read_r += getline(&line_r3, &len, rfp);
          read_r += getline(&line_r4, &len, rfp);
          
          char * str_l = (char *) malloc(400);
          char * str_r = (char *) malloc(400);
          strcpy (str_l, line_l1);
          strcat (str_l, line_l2);
          strcat (str_l, line_l3);
          strcat (str_l, line_l4);

          strcpy (str_r, line_r1);
          strcat (str_r, line_r2);
          strcat (str_r, line_r3);
          strcat (str_r, line_r4);

          a = 1.0;
          if (count <= nc) {
            res_l[count-1] = str_l;
            res_r[count-1] = str_r;
          } else {
            r = ((float)rand()/(float)(RAND_MAX)) * a;
            if (r < (float)nc/(float)count) {
              i = rand() % nc;
              res_l[i] = str_l;
              res_r[i] = str_r;
            } else {
              free(str_l);
              free(str_r);
            }
          }
          ++count;
        }

        fclose(lfp);
        fclose(rfp);

        FILE *lout = fopen(outname_left, "w");
        FILE *rout = fopen(outname_right, "w");

        if (lout == NULL) {
            printf("Error opening left file for writing\\n");
            exit(1);
        }
        if (rout == NULL) {
            printf("Error opening right file for writing\\n");
            exit(1);
        }

        for(i=0; i<nc; i++) {
          fprintf(lout,"%s",res_l[i]);
          fprintf(rout,"%s",res_r[i]);
        }

        fclose(lout);
        fclose(rout);
      }
SRC
    end

    # Take a uniform random subsample of n reads from
    # each of the input FASTQ files @left and @right
    # using reservoir sampling. Return an array of length
    # 2, containing the paths to the left and right subsampled
    # read files.
    #
    # @param n [Integer] the number of read pairs to sample.
    # @param seed [Integer] seed for the random number generator
    #   (optional).
    # @return [Array<String>] array of length two containing the
    #   paths to the left and right FASTQ samples.
    def subsample(n, seed = 1337)
      ldir = File.dirname(@left)
      loutfile = File.join(ldir, "subset.#{File.basename @left}")

      rdir = File.dirname(@right)
      routfile = File.join(rdir, "subset.#{File.basename @right}")

      subsampleC(n, seed, @left, @right, loutfile, routfile)
      
      [loutfile, routfile]
    end

  end

end
