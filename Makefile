# Основная цель - имя верхнего модуля.
TARGET    = test

# Файлы модулей.
SOURCES   = test.v

# Макросы.
DEFINES   += 

# Путь к собственным библиотекам в исходниках.
SRC_LIBS_PATH     = ../lib
# Пути ко всем собственным библиотекам в исходниках.
SRC_LIBS_ALL_PATH = $(wildcard $(addsuffix /*, $(SRC_LIBS_PATH)))

# Пути с исходниками.
VPATH   += .
VPATH   += $(SRC_LIBS_ALL_PATH)

# Цель компиляции.
# null, vvp, fpga, vhdl.
IVTARGET  = vvp

# Флаги компилятора.
# Дополнительные
IVFLAGS += -g2005-sv
# Цель.
IVFLAGS   += -t$(IVTARGET)
# Корневой модуль.
IVFLAGS   += -s $(TARGET)
# Макросы.
IVFLAGS   += $(addprefix -D, $(DEFINES))
# Папка с библиотеками
IVFLAGS   += -I $(SRC_LIBS_PATH)

# Тулкит.
VERILOG_PREFIX=
IV      = $(TOOLKIT_PREFIX)iverilog
VVP     = $(TOOLKIT_PREFIX)vvp

# GTKWave
GTKWAVE = gtkwave --save=test.gtkw --fastload

# Прочие утилиты.
RM      = rm -f

# Побочные цели.
# Файл для симуляции.
TARGET_VVP = $(TARGET).vvp
# Файл осциллограмм.
TARGET_VCD = $(TARGET).vcd

all: $(TARGET_VCD)

$(TARGET_VCD): $(TARGET_VVP)
	$(VVP) $^

$(TARGET_VVP): $(SOURCES)
	$(IV) -o $@ $(IVFLAGS) $^

clean:
	$(RM) $(TARGET_VCD)
	$(RM) $(TARGET_VVP)

clean_all: clean

view: $(TARGET_VCD)
	$(GTKWAVE) $^ 2>/dev/null 1>/dev/null &
