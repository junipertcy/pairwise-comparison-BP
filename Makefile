CPP = g++
OUT_DIR = out

# --- Targets ---
TARGETS := LEMP PDP fixedCost arbKernel
LIBS    := $(addprefix $(OUT_DIR)/, $(addsuffix .so, $(TARGETS)))
OBJS    := $(patsubst %.so,%.o,$(LIBS))

.PHONY: all clean LEMP pop-dyn-planted fixed-cost arb-kernel
all: LEMP pop-dyn-planted fixed-cost arb-kernel

# --- Platform-specific Configuration ---
ifeq ($(shell uname -s), Darwin)
    # macOS (requires: brew install fftw libomp eigen)
    CPPFLAGS := -std=c++17 -fPIC -O3 -Xpreprocessor -fopenmp -I./inc -I/opt/homebrew/include/eigen3 -I/opt/homebrew/opt/libomp/include -I/opt/homebrew/include
    LDFLAGS  := -L/opt/homebrew/opt/libomp/lib -L/opt/homebrew/lib -lomp -lfftw3 -lfftw3l
else
    # Linux (requires: apt-get install build-essential libeigen3-dev libfftw3-dev libquadmath-dev)
    CPPFLAGS := -std=c++17 -fPIC -I./inc -I/usr/include/eigen3 -march=native -O3 -fopenmp
    LDFLAGS  := -lfftw3 -lfftw3l -lquadmath -lm
endif

# --- Build Rules ---
LEMP:            $(OUT_DIR)/LEMP.so
pop-dyn-planted: $(OUT_DIR)/PDP.so
fixed-cost:      $(OUT_DIR)/fixedCost.so
arb-kernel:      $(OUT_DIR)/arbKernel.so

$(LIBS) $(OBJS): | $(OUT_DIR)
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# --- Compilation ---
# Generic rule to compile any .cpp file from src/ into an object file in out/
$(OUT_DIR)/%.o: src/%.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

# Handle source files with names that don't match the target name
$(OUT_DIR)/fixedCost.o: src/fixed-cost.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

$(OUT_DIR)/arbKernel.o: src/arbitrary-kernel.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

$(OUT_DIR)/PDP.o: src/PopDynPlanted.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

# --- Linking ---
# Generic rule to link a shared library from its object file, with platform-specific commands.
$(OUT_DIR)/%.so: $(OUT_DIR)/%.o
ifeq ($(shell uname -s), Darwin)
	$(CPP) -shared -o $@ $< $(LDFLAGS)
else
	$(CPP) -shared -Wl,-soname,$(notdir $@) -o $@ $< $(LDFLAGS)
endif

# --- Housekeeping ---
clean:
	rm -f $(OUT_DIR)/*.o $(OUT_DIR)/*.so
