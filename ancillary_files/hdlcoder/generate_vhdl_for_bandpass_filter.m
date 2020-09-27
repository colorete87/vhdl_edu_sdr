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
% run('../sim_edu_bbt/system_parameters.m');
% fsymb = 1./Tsymb;
% fs    = 1./Ts;
filter_data = dlmread('../coeffs_generators/data/symb_sync_bp_filter.dat');
filter_b    = filter_data(1,:);
filter_a    = filter_data(2,:);
%-----------------------------------------------------------


%-----------------------------------------------------------
% Create filter and hdl
%-----------------------------------------------------------
% MyFilter = dfilt.dffir(spar.pulse./sum(spar.pulse.^2));
MyFilter = dfilt.df1sos(filter_b,filter_a);
MyFilter.arithmetic = 'fixed';
% MyFilter.FilterInternals='FullPrecision';
% MyFilter.FilterInternals='SpecifyPrecision';
MyFilter.InputWordLength = 13;
MyFilter.InputFracLength = 10;
MyFilter.OutputWordLength = 20;
% MyFilter.OutputFracLength = 8;
% generatehdl(MyFilter);
generatehdl(MyFilter, ...
  'Name','hdlcoder_bandpass_filter', ...
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


%-----------------------------------------------------------
% PLOT
%-----------------------------------------------------------
figure();
freqz(filter_b,filter_a);
%-----------------------------------------------------------

