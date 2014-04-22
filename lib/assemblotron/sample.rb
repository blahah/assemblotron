require 'inline'

module Assemblotron

  class Sample

    # Return a new Sample with left and right reads
    def initialize(left, right)
      @left = left
      @right = right
    end

    inline :C do |builder|
      builder.include '<stdio.h>'
      builder.include '<strings.h>'
      builder.c <<SRC
        void subsampleC(VALUE n, VALUE left, VALUE right, VALUE leftout, VALUE rightout) {
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
          unsigned nc, i;
          float a, r;
          unsigned long count;
          FILE *lfp;
          FILE *rfp;
          FILE *lout;
          FILE *rout;
          char *res_l = NULL;
          char *res_r = NULL;

          nc = NUM2INT(n);
          res_l = (char*) realloc(res_l, nc * sizeof(char));
          res_r = (char*) realloc(res_r, nc * sizeof(char));
          srand(11);

          filename_left = StringValueCStr(left);
          filename_right = StringValueCStr(right);
          outname_left = StringValueCStr(leftout);
          outname_right = StringValueCStr(rightout);

          lfp = fopen(filename_left, "r");
          rfp = fopen(filename_right, "r");

          if (lfp == NULL) {
            fprintf(stderr, "Cant open file!\\n");
            exit(1);
          }
          if (rfp == NULL) {
            fprintf(stderr, "Cant open file!\\n");
            exit(1);
          }

          count = 1;
          while ((read_l = getline(&line_l1, &len, lfp)) != -1) {
            char * str_l = (char *) malloc(400);
            char * str_r = (char *) malloc(400);

            read_l += getline(&line_l2, &len, lfp);
            read_l += getline(&line_l3, &len, lfp);
            read_l += getline(&line_l4, &len, lfp);
            read_r =  getline(&line_r1, &len, rfp);
            read_r += getline(&line_r2, &len, rfp);
            read_r += getline(&line_r3, &len, rfp);
            read_r += getline(&line_r4, &len, rfp);
            
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
                if (i < 0 || i >= nc) {
                  printf("ERROR, index out of bounds exception");
                }
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

          lout = fopen(outname_left, "w");
          rout = fopen(outname_right, "w");

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
    # using reservoir sampling.
    def subsample(n, seed = 1337)
      ldir = File.dirname(@left)
      loutfile = File.join(ldir, "subset.#{File.basename @left}")

      rdir = File.dirname(@right)
      routfile = File.join(rdir, "subset.#{File.basename @right}")

      subsampleC(n,seed, @left, @right, loutfile, routfile)

      [loutfile, routfile]
    end

  end

end
