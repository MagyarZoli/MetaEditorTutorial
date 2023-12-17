#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

input int inpPeriod = 20; //period
input int inpOffset = 0; //offset in of % channel
input color inpColor = clrBlue; //color

double bufferUpper[];
double bufferLower[];
double upper, lower;
int first, bar;

int OnInit() {
  InitializeBuffer(0, bufferUpper, "Donchian Upper");
  InitializeBuffer(1, bufferLower, "Donchian Lower");
  IndicatorSetString(INDICATOR_SHORTNAME, "Donchian(" + IntegerToString(inpPeriod) + ")");
  return(INIT_SUCCEEDED);
}

int OnCalculate(
  const int rates_total,
  const int prev_calculated,
  const datetime &time[],
  const double &open[],
  const double &high[],
  const double &low[],
  const double &close[],
  const long &tick_volume[],
  const long &volume[],
  const int &spread[]
) {
  if (rates_total < inpPeriod + 1) {
    return 0;
  }
  
  first = prev_calculated == 0 ? inpPeriod : prev_calculated - 1;
  
  for (bar = first; bar < rates_total; bar++) {
    upper = open[ArrayMaximum(open, bar - inpPeriod + 1, inpPeriod)];
    lower = open[ArrayMinimum(open, bar - inpPeriod + 1, inpPeriod)];
    
    bufferUpper[bar] = upper - (upper - lower) * inpOffset * 0.01;
    bufferLower[bar] = lower + (upper - lower) * inpOffset * 0.01;
  }
  
  return(rates_total);
}

void InitializeBuffer(int index, double &buffer[], string label) {
  SetIndexBuffer(index, buffer, INDICATOR_DATA);
  PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_LINE);
  PlotIndexSetInteger(index, PLOT_LINE_WIDTH, 2);
  PlotIndexSetInteger(index, PLOT_DRAW_BEGIN, inpPeriod - 1);
  PlotIndexSetInteger(index, PLOT_SHIFT, 1);
  PlotIndexSetInteger(index, PLOT_LINE_COLOR, inpColor);
  PlotIndexSetString(index, PLOT_LABEL, label);
  PlotIndexSetDouble(index, PLOT_EMPTY_VALUE, EMPTY_VALUE);
}