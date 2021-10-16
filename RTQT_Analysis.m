function RTQT_Analysis



%% Set up the figure
fig = figure('Name','RTQT_Analysis ','Visible','off','Position',[50 100 1400 800]);
movegui(fig,'center')

% set(fig_histogram,'Visible','off');

% Buttons
loadButton = uicontrol(fig,'Style','pushbutton','String','Dateiordner',...
    'Position',[50 500 80 30],'Callback', {@loadButton_Callback});
analyseButton = uicontrol(fig,'Style','pushbutton','String','Analysieren',...
    'Position',[150 450 80 30],'Enable','off','Callback', {@analyseButton_Callback});
reloadButton = uicontrol('Style','pushbutton','String','Ordnerupdate',...
    'Position',[150 500 80 30],'Enable','off','Callback', {@reloadButton_Callback});
saveSELECTED_RESIDUALbutton = uicontrol('Style','pushbutton','String','Quads sichern',...
    'Position',[50 450 80 30],'Enable','off','Callback', {@saveQuadButton_Callback});




% Text fields
textDataSets = uicontrol(fig,'Style','text','Position', [40 400 100 30],...         %,'BackgroundColor',[0.8 0.8 0.8]
    'String','Anzahl Datensaetze:');

text_label_loading_time = uicontrol(fig,'Style','text','FontSize',8,'Position', [42 85 46 30],...
    'String','Ladezeit: (s)');
text_loading_time = uicontrol(fig,'Style','text','FontSize',8,'Position', [120 85 60 30],...
    'String','','HorizontalAlignment','Left');

text_label_calculation_time = uicontrol(fig,'Style','text','FontSize',8,'Position', [20 55 91 30],...
    'String','Berechnungszeit: (s)');
text_calculation_time = uicontrol(fig,'Style','text','FontSize',8,'Position', [120 55 60 30],...
    'String','','HorizontalAlignment','Left');

text_label_byteSize_Data = uicontrol(fig,'Style','text','FontSize',8,'Position', [20 25 91 30],...
    'String','Belegter Speicher: (MB)');
text_byteSize_Data = uicontrol(fig,'Style','text','FontSize',8,'Position', [120 25 60 30],...
    'String','','HorizontalAlignment','Left');

text_photonnumber = uicontrol(fig,'Style','text','FontSize',11,'Position', [715 100 120 20],...
    'String','Quadratur:');
text_mean_Quad_result = uicontrol(fig,'Style','text','FontSize',9,'Position', [700 75 60 20],...            %average photonnumber
    'String','','HorizontalAlignment','Right');
text_Plus_Minus_Quad = uicontrol(fig,'Style','text','FontSize',9,'Position', [767 75 6 20],...
    'String',char(177));
text_mean_var_Quad_deviation = uicontrol(fig,'Style','text','FontSize',9,'Position', [778 75 60 20],...     %deviation of average photonnumber
    'String','','HorizontalAlignment','Left');

text_label_g2Factor = uicontrol(fig,'Style','text','FontSize',11,'Position', [1040 100 70 20],...
    'String','g2-Faktor:');
text_g2_result = uicontrol(fig,'Style','text','FontSize',9,'Position', [1005 75 60 20],...
    'String','','HorizontalAlignment','Right');
text_Plus_Minus_gsFactor = uicontrol(fig,'Style','text','FontSize',9,'Position', [1070 75 6 20],...
    'String',char(177));
text_g2_deviation = uicontrol(fig,'Style','text','FontSize',9,'Position', [1081 75 60 20],...
    'String','','HorizontalAlignment','Left');

% Edit filename
editDataSets= uicontrol(fig,'Style','edit','Position', [170 405 40 20],'String','1000','Callback',@editDataSets_Callback);


% Listbox
listbox = uicontrol('Style','listbox','Units','pixel','Position',[50 570 400 200],'Callback',@select_only_two);
set(listbox,'Max',2,'Min',0);

% Graphs
ha1 = axes(fig,'Units','pixels','Position',[530,670,800,100]);
ax1 = subplot(ha1);
title(ha1, 'Mittelwert über alle Datensaetze');
xlabel(ha1, 'Zeit in ns');
ylabel(ha1, 'U_{diff} in V');

ha2 = axes(fig,'Units','pixels','Position',[530,515,800,100]);
ax2 = subplot(ha2);
title(ax2, 'Berechnete Varianz und Peaks');
xlabel(ax2, 'Zeit in ns');
ylabel(ax2, '(\Delta U_{diff})^2 = var(U_{diff})');
set(fig,'Visible','on');

ha3 = axes(fig,'Units','pixels','Position',[530,185,800,255]);
ax3 = subplot(ha3);
set(gca,'fontsize',12);
title(ax3, 'Histogramm','FontSize', 13);
xlabel(ax3, 'Quadraturen','FontSize', 11);
ylabel(ax3, 'Häufigkeit','FontSize', 11);
set(fig,'Visible','on');


% Global variables
num_dataSets = str2double(get(editDataSets,'String'));
mean_Quad = [];
mean_var_Quad =[];
mean_N_diffLO = [];
mean_var_N_diffLO = [];

N_diffLO = [];
Quad =  [];                                                                 % Quad = Quadrature
path_to_files = [];
fulllist = [];
loading_time = 0;
calculation_time = 0;
Data = []'; 
Data_selecS1 = [];
Data_selecS0 = [];
calc_Data = [];
calc_DataS1 = [];
calc_DataS0 = [];
timestamps = [];
old_selected_file = [];
old_selected_files = ['file1','file2'];
ada = [];
selected_files = [];

% calc Quads
speed_of_light = 299792459;      % m / s
planck = 6.626070040e-34;        % J * s
lambda = 834e-9;                 % m
omegaLO = 79.93e6;               % 1/s
gain = 2.7e3;                    % V/W
detector_area = (0.8e-3/2)^2*pi; % pi*r^2

%% --------------------LIMITED LISTBOXSELECTION FUNCTION ----------------
    function select_only_two(h,~)
        previous_Values = get(h,'UserData');
        current_Values = get(h,'Value');
        if numel(current_Values) > 2                                         %numel returns the number of array elements 
            current_Values = previous_Values;
        end
        set(h,'Value',current_Values)
        set(h,'UserData',current_Values)
    end

%% ------------------------ LOAD BUTTON --------------------------------
    function loadButton_Callback(source,eventdata)
        path_to_files = [];
        set(listbox,'Value',1);
        path_to_files= uigetdir('.txt','Select a file');
        handles.output = listbox;
        
        try
           files = dir(fullfile(path_to_files,'*.txt'));
           if length(files) <1
                errordlg('Error: No data was imported!');
                set(listbox,'String','feed me with data');
                set(analyseButton,'Enable','off');
                set(reloadButton,'Enable','off');
           else
                for x = 1 : length(files)
                    handles.text{x} = fullfile(path_to_files,files(x).name);
                end
                set(listbox,'String',{files.name});
                guidata(listbox, handles);
                fulllist = get(listbox,'String');
                set(analyseButton,'Enable','on');
                set(reloadButton,'Enable','on');
           end
            
        catch files
                files = 0;
                set(listbox,'String','feed me with data');
                errordlg('Error: No valid folder is selected! Data cannot be imported.');
                %error('MATLAB:FileManip:NullCharacterInName',...
                %    'Error: No valid folder is selected! Data cannot be imported.');
            
        end
        
    end

%% ------------------------ PLOT BUTTON --------------------------------
    function analyseButton_Callback(editDataSets,textString)
        
        %% Set up the data
        
        % Clear all variables
        mean_Quad = [];
        mean_var_Quad= [];
        Quad =  [];
        timestamps = [];
        set(saveSELECTED_RESIDUALbutton,'Enable','on');
        % select file out of the listbox     
        selected_files = string(fulllist(get(listbox,'Value')));
        if length(selected_files) == 1 
           selec_file = char(selected_files(1));
           string_compare = strcmp(selec_file,old_selected_file);
           if string_compare == 0
              t1 = tic;
              Data = readmatrix(fullfile(path_to_files,selec_file))';
              loading_time = toc(t1);
              set(text_loading_time,'String',num2str(loading_time));
              old_selected_file = selec_file;
            else
              set(text_loading_time,'String','Bereits geladen');
           end
           timestamps= Data(1,1:end);
           [size_xData, size_yData] = size(Data);        
           [calc_Data,num_dataSets] = check_numDataSetsFct(num_dataSets,size_xData,Data);          % check if the wanted amount of data sets is valid
           [mean_Data,var_Data,var_locs,var_pks]...
               = calc_DataFct(calc_Data);              
            s = whos('calc_Data');
            byteSize_Data = s.bytes /1e6;                                       %in MB
            set(text_byteSize_Data,'String',num2str(byteSize_Data)); 
            
        else
            %% evtl. wenn Zeit Funktion schreiben die selected_files umsortiert damit s0 von s1 abgezogen wird
            string_compare = strcmp(selected_files(),old_selected_files);
            if string_compare(1) == 0 || string_compare(2) == 0
               expression_s1 = '(_s1_)';                                         
               [match] = regexp(selected_files,expression_s1,'match');
               if match{2} == ('_s1_');            
                  t1 = tic;
                  Data_selecS1 = readmatrix(fullfile(path_to_files,char(selected_files(2))))';               %% selected_files(2) includes s1
                  Data_selecS0 = readmatrix(fullfile(path_to_files,char(selected_files(1))))';               %% selected_files(1) includes s0
                  loading_time = toc(t1);
                  set(text_loading_time,'String',loading_time);
                  old_selected_files = selected_files;
               else
                  t1 = tic;
                  Data_selecS1 = readmatrix(fullfile(path_to_files,char(selected_files(1))))';               %% selected_files(1) includes s1
                  Data_selecS0 = readmatrix(fullfile(path_to_files,char(selected_files(2))))';               %% selected_files(2) includes s0
                  loading_time = toc(t1);
                  set(text_loading_time,'String',loading_time);
                  old_selected_files = selected_files;   
               end
             else
                 set(text_loading_time,'String','Bereits geladen');
             end
             timestamps= Data_selecS1(1,1:end);
             [size_xDataS1, size_yData] = size(Data_selecS1);
             [size_xDataS0, size_yData] = size(Data_selecS0); 
             [calc_DataS1,num_dataSets] = check_numDataSetsFct(num_dataSets,size_xDataS1,Data_selecS1);
             [calc_DataS0,num_dataSets] = check_numDataSetsFct(num_dataSets,size_xDataS0,Data_selecS0); 
             [mean_DataS1,mean_DataS0,var_DataS1,var_DataS0,var_locsS1,var_pksS1,var_locsS0,var_pksS0]... 
                 = calc_DataFct2();
             s1 = whos('calc_DataS1');
             s0 = whos('calc_DataS0');
             byteSize_Data = (s1.bytes + s0.bytes) /1e6;                                       %in MB
             set(text_byteSize_Data,'String',num2str(byteSize_Data)); 
        end   

        %% Plots
        if length(selected_files) == 1
            plot(ax1,timestamps,mean_Data,'b');
            title(ha1, 'Mittelwert über alle Datensätze');
            xlabel(ha1, 'Zeit in ns');
            ylabel(ha1, 'U_{diff} in V');
            plot(ax2, timestamps,var_Data,'b',timestamps(var_locs), var_pks,'or');
            title(ha2, 'Berechnete Varianz und Peaks');
            xlabel(ha2, 'Zeit in ns');
            ylabel(ha2, '(\Delta U_{diff})^2 = var(U_{diff})');
            histogram(ax3,N_diffLO);
            title(ax3,'Histogramm','FontSize', 13);
            xlabel(ax3, 'Quadraturen','FontSize', 11);
            ylabel(ax3, 'Häufigkeit','FontSize', 11);
        else
            plot(ax1,timestamps,mean_DataS1,'b',timestamps,mean_DataS0,'g');
            title(ha1, 'Mittelwert über alle Datensätze');
            xlabel(ha1, 'Zeit in ns');
            ylabel(ha1, 'U_{diff} in V');
            plot(ax2, timestamps,var_DataS1,'b',timestamps(var_locsS1),var_pksS1,'or');
            hold(ax2,'on')
            plot(ax2, timestamps,var_DataS0,'g',timestamps(var_locsS0),var_pksS0,'om');
            hold(ax2,'off')
            title(ha2, 'Berechnete Varianz und Peaks');
            xlabel(ha2, 'Zeit in ns');
            ylabel(ha2, '(\Delta U_{diff})^2 = var(U_{diff})');
            histogram(ax3,Quad);
            set(gca,'fontsize',8);
            title(ax3,'Histogramm','FontSize', 13);
            xlabel(ax3, 'Quadraturen','FontSize', 11);
            ylabel(ax3, 'Häufigkeit','FontSize', 11);
        end
        

        
    end

%% -------------------- CALC DATA FUNCTION TWO FILES -----------------------
    function [mean_DataS1,mean_DataS0,var_DataS1,var_DataS0,var_locsS1,var_pksS1,var_locsS0,var_pksS0,timestamps_Quad] = calc_DataFct2()
         
        % Data processing
        processing_msg = msgbox("Processing...");
        t2 = tic;
        
        mean_DataS1 = mean(calc_DataS1);
        var_DataS1 = var(calc_DataS1);
        mean_DataS0 = mean(calc_DataS0);
        var_DataS0 = var(calc_DataS0);
        [var_pksS1, var_locsS1]= findpeaks(var_DataS1,'MinPeakDistance',30);
        [var_pksS0, var_locsS0]= findpeaks(var_DataS0,'MinPeakDistance',30);
        % preallocating to get 0.1s less calculation time
        length_var_locs = length(var_locsS1)-2;
        U_diffS1(1:num_dataSets,1:length_var_locs) = 0;
        U_diffS0(1:num_dataSets,1:length_var_locs) = 0;
        timestamps_Quad(1:length_var_locs) = 0;
        var_Quad(1:length_var_locs) = 0;

        
        % get N_diff from x*7,5ns to x*16,5ns with x [1,2,3,4,5,...]
        for i= 1:num_dataSets
            for j = 1:length_var_locs
                U_diffS1(i,j) = sum(calc_DataS1(i,((var_locsS1(j+1)-15)):(var_locsS1(j+1)+15)))*detector_area;  %30 corresponds to 10ns ; maxium is 36 corresponds to 12ns 
                U_diffS0(i,j) = sum(calc_DataS0(i,((var_locsS0(j+1)-15)):(var_locsS0(j+1)+15)))*detector_area;
                timestamps_Quad(j) = timestamps(var_locsS1(j+1));
            end
        end
        
        
        
        % calc N_diff                                            
        power_S1 = U_diffS1/gain;                                           %V / (V/W) go get W
        power_S0 = U_diffS0/gain;
        
        Ndiff_S1 = power_S1 / ...                                           %compute N photons  hier wurde schon das ferttige zeitlichbe Inetegral gebildet und jetzt werden die SPannungswerte umgerechnet                                     
            (planck * speed_of_light / lambda * omegaLO); % per pulse optische Leistung !
        Ndiff_S0 = power_S0 / ...
            (planck * speed_of_light / lambda * omegaLO); % per pulse
       
        
        %normalizing Quads
        NLO = mean(var(Ndiff_S0));                                           %amount of LO-photons 
        Norm = sqrt(2);
        Quad = Norm * Ndiff_S1/ sqrt(NLO);                                  %real light signal
        
        %variance Quad
        for i = 1:length_var_locs
            var_Quad(i) = mean(Quad(:,i).^2) - mean(Quad(:,i)).^2;
        end
        
        
        %mean Quad
        mean_Quad = mean(mean(Quad));
        disp(mean_Quad)
        set(text_mean_Quad_result,'String',num2str(mean_Quad,'%.2f'));
        
        %mean Var(Quad)
        mean_var_Quad = mean(var_Quad);
        mean_var_Quad_deviation = sqrt(mean_var_Quad);
        set(text_mean_var_Quad_deviation,'String',num2str(mean_var_Quad_deviation,'%.2f'));
        
        % g2 calculation
        [g2vec, ada] = calc_g2(Quad);                                       %ada anzahl photonen
        set(text_g2_result,'String',num2str(mean(g2vec),'%.2f'));
        set(text_g2_deviation,'String',num2str(sqrt(var(g2vec)),'%.2f'));
        % end calculation time
        calculation_time=toc(t2);
        set(text_calculation_time,'String',num2str(calculation_time,'%.2f'))
        close(processing_msg);
    end

%% ------------------- CALC DATA FUNCTION ONE FILE-------------------------------
    function [mean_Data,var_Data,var_locs,var_pks] =calc_DataFct(calc_Data)
        % Data processing
        processing_msg = msgbox("Processing...");
        t2 = tic;
        mean_Data = mean(calc_Data);
        var_Data = var(calc_Data);
        [var_pks, var_locs]= findpeaks(var_Data,'MinPeakDistance',30);
        
        % preallocating to get 0.04s less calculation time
        U_diffLO(1:num_dataSets,1:length(var_locs)-2) = 0;
        timestamps_Quad(1:length(var_locs)-2) = 0;
        var_Quad(1:length(var_locs)-2) = 0;

        % get N_diff from x*7,5ns to x*16,5ns with x [1,2,3,4,5,...]
        for i= 1:num_dataSets
            for j = 1:length(var_locs)-2
                U_diffLO(i,j) = sum(calc_Data(i,((var_locs(j+1)-15)):(var_locs(j+1)+15)))*detector_area;  %30 corresponds to 10ns ; maxium is 36 corresponds to 12ns 
                timestamps_Quad(j) = timestamps(var_locs(j+1));
            end
        end
        

        % calc Quads
        %COMPUTENPHOTONS Computes the number of photons per pulse of a laser beam
        %with power POWERLO, wavelength LAMBDA and repetition rate FREQUENCYLO
        
        power_LO = U_diffLO/gain;                                             %V / (V/W) go get W
        N_diffLO = power_LO / ...                                                 %Quad :=  N_diff because no norm
            (planck * speed_of_light / lambda * omegaLO); % per pulse

        %variance Quad
        for i = 1:length(var_locs)-2
            var_N_diffLO(i) = mean(N_diffLO(:,i).^2) - mean(N_diffLO(:,i)).^2;
        end
        %mean Quad
        mean_N_diffLO = mean(mean(N_diffLO));
        set(text_mean_Quad_result,'String',num2str(mean_N_diffLO,'%.2f'));
        
        %mean Var(Quad)
        mean_var_N_diffLO = mean(var_N_diffLO);
        mean_var_N_diffLO_deviation = sqrt(mean_var_N_diffLO);
        set(text_mean_var_Quad_deviation,'String',num2str(mean_var_N_diffLO_deviation,'%.2f'));

        % g2 calculation
        [g2vec, ada] = calc_g2(N_diffLO);
        
        set(text_g2_result,'String',num2str(mean(g2vec),'%.2f'));
        set(text_g2_deviation,'String',num2str(sqrt(var(g2vec)),'%.2f'));
        % end calculation time
        calculation_time=toc(t2);
        set(text_calculation_time,'String',num2str(calculation_time,'%.2f'))
        close(processing_msg);
    end

%% ---------------- CHECK NUMBER DATA SETS FUNCTION ---------------------   % check if the wanted amount of data sets is valid
    function [calc_Data,num_dataSets] = check_numDataSetsFct(num_dataSets, size_xData,check_Data)  
            if  num_dataSets+1 > size_xData
                calc_Data = check_Data(2:size_xData, 1:end);
                calc_Data = calc_Data - mean(mean(calc_Data));
                num_dataSets = size_xData-1;
                refresh_editField(num_dataSets);
                warndlg('Die gefordete Anzahl an Datensaetzen kann nicht geladen werden. Es wird die maximale Anzahl an Datensaetzen der Datei geladen.');

            else
                calc_Data = check_Data(2:num_dataSets+1, 1:end); 
                calc_Data = calc_Data - mean(mean(calc_Data));
            end
    end


%% -------------------------- RELOAD BUTTON ------------------------------
    function reloadButton_Callback(source,eventdata)
        set(analyseButton,'Enable','on');
        handles.output = listbox;
        files = dir(fullfile(path_to_files,'*.txt'));
        for x = 1 : length(files)
            handles.text{x} = fullfile(path_to_files,files(x).name);
        end
        set(listbox,'String',{files.name});
        guidata(listbox, handles);
        fulllist = get(listbox,'String');
    end

%% ---------------------- REFRESH CALLBACKS -----------------------------
    function editDataSets_Callback(editDataSets,event)
        num_dataSets = str2double(get(editDataSets,'String'));
    end

    function refresh_editField(num_dataSets)
        set(editDataSets,'String',num_dataSets);
    end

%% ---------------------------- saveQuadButton CALLBACK
    function saveQuadButton_Callback(source,eventdata)
        selected_files = string(fulllist(get(listbox,'Value')));
        x = 1;
        mkdir([path_to_files '\Quadratures'])            
        QuadOutput = Quad(:,2:end);           
        save_file = [path_to_files '\Quadratures\QUAD_' char(selected_files(x))];      
        dlmwrite(save_file, QuadOutput,'precision',9,'delimiter','\t','newline','pc');
    end

%% ------------------------ FFT CALCULATION ----------------------------
    function [f, FFT] =  getFFT(xd, yd)
        %%% HAMMING FFT %%%
        xd;
        yd;
        %         h=hamming(length(yd),'periodic');
        h = rectwin(length(yd));
        hyd=yd.*h;
        pof2=pow2(nextpow2(length(yd))+1);
        sample_period = (xd(2)-xd(1)); %find sample period%
        sample_freq = 1/sample_period;
        [FT] = fft(hyd,pof2);
        f=(0:pof2/2-1)*(sample_freq/pof2);
        bFT=FT(1:length(FT)/2);
        FFT=((bFT.*(conj(bFT)/pof2)*(pi/2))).^(1/2);
        %     dt = xdata(2)-xdata(1); % time interval
        %     Fs = 1/dt; % frequency
        %     N = floor(length(xdata)/2); % signal length (FFT gives symmetric spectrum -> / 2)
        %     f = (0:N)/length(xdata) * Fs; % frequencies for FFT
        %     Spectrum = fft(ydata);
        %     FFT = abs(Spectrum(1:N+1));

    end

%% ----------------------- CALCULATE PHOTONS ---------------------------
    function [nPhotons] = computeNPhotons(powerLO, lambda, frequencyLO)
        %COMPUTENPHOTONS Computes the number of photons per pulse of a laser beam
        %with power POWERLO, wavelength LAMBDA and repetition rate FREQUENCYLO
        
        SPEED_OF_LIGHT = 299792459; % m / s
        PLANCK = 6.626070040e-34; % J * s
        
        nPhotons = powerLO / ...
            (PLANCK * SPEED_OF_LIGHT / lambda * frequencyLO); % per pulse
    end

%% ----------------------- CALCULATE g2-FACTOR ---------------------------
    function [g2vec, ada] = calc_g2(X)
        X = X - mean(mean(X));
        ada = mean(X.^2)-0.5;                                               %photonenzahl aus quads
        adadaa = 2/3*mean(X.^4)-2*ada-0.5;
        g2vec = adadaa./ada.^2;
        g2vec = g2vec';
    end


end