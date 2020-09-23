%-----------------------------------------------------------
% Preamble
%-----------------------------------------------------------
close all;
clear all;
clc;
format('compact');
addpath(genpath('../sim_edu_bbt/funcs/'));
addpath(genpath('../lib/'));
%-----------------------------------------------------------


%-----------------------------------------------------------
% Parameters
%-----------------------------------------------------------
run('../sim_edu_bbt/system_parameters.m');
fsymb = 1./Tsymb;
fs    = 1./Ts;
%-----------------------------------------------------------


%-----------------------------------------------------------
% Create filter and hdl
%-----------------------------------------------------------
MyFilter = dfilt.dffir(pulse);
MyFilter.arithmetic = 'fixed';
% MyFilter.FilterInternals='FullPrecision';
MyFilter.FilterInternals='SpecifyPrecision';
MyFilter.InputWordLength = 2;
MyFilter.InputFracLength = 0;
MyFilter.OutputWordLength = 10;
MyFilter.OutputFracLength = 8;
% generatehdl(MyFilter);
generatehdl(MyFilter, ...
  'Name','hdlcoder_pulse_shaping_fir', ...
  'TargetLanguage','VHDL', ...
  'GenerateHDLTestbench', 'on' ...
);
% generatehdl(MyFilter, ...
%   'InputDataType',numerictype(1,16,15), ...
%   'Name','pulse_shaping_filter', ...
%   'TargetLanguage','VHDL', ...
%   'GenerateHDLTestbench', 'on' ...
% )
%-----------------------------------------------------------

