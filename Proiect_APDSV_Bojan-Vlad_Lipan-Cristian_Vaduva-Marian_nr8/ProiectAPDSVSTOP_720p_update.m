clear
close all
clc





% === Detector Training ===


load('rcnnStopSigns.mat', 'stopSigns', 'layers')
imDir = fullfile(matlabroot, 'toolbox', 'vision', 'visiondata',...
  'stopSignImages');
addpath(imDir);
options = trainingOptions('sgdm', ...
  'MiniBatchSize', 32, ...
  'InitialLearnRate', 1e-6, ...
  'MaxEpochs', 10);
rcnn = trainRCNNObjectDetector(stopSigns, layers, options, 'NegativeOverlapRange', [0 0.3]);

% === Testing Detector ===

img = imread('maxresdefault.jpg');

[bbox, score, label] = detect(rcnn, img, 'MiniBatchSize', 32);
[score, idx] = max(score);

bbox = bbox(idx, :);
annotation = sprintf('%s: (Confidence = %f)', label(idx), score);

detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, annotation);

figure
imshow(detectedImg)
rmpath(imDir);



% === Video Processing ===

% === 5m ===


OBJ = VideoReader('ref_5m_720_2.mp4');

numar_cadre_5m = get(OBJ,'NumberOfFrames');
fprintf('Numar de cadre_5m = %d\n', numar_cadre_5m);

fid=fopen('ref_5m_720.txt','w');

for k = 1 : 70
   
    [bboxc, score, label] = detect(rcnn, read(OBJ,k), 'MiniBatchSize', 32);
    [score, idx] = max(score);
    bboxc = bboxc(idx, :);
    fprintf(fid, '%d %d %d %d \n', bboxc );
    detectedimg5m = insertObjectAnnotation(read(OBJ,k), 'rectangle', bboxc, annotation);
    detected_vid_5m(:,:,:,k) = detectedimg5m;
    
end

fclose(fid);
implay(detected_vid_5m);

fid = fopen('ref_5m_720.txt','r');
formatSpec = '%d';

det_vect_5m = fscanf(fid, formatSpec);

%
m_5m = det_vect_5m(4:4:120);
medie_5m = mean(m_5m);




% === 7.5m ===

OBJ2 = VideoReader('ref_75m_720.mp4');

numar_cadre_75m = get(OBJ2,'NumberOfFrames');
fprintf('Numar de cadre_7.5m = %d\n', numar_cadre_75m);

fid=fopen('ref_75m_720.txt','w');

for k = 1 : 70
   
    [bbox75m, score, label] = detect(rcnn, read(OBJ2,k), 'MiniBatchSize', 32);
    [score, idx] = max(score);
    bbox75m = bbox75m(idx, :);
    fprintf(fid, '%d %d %d %d \n', bbox75m );
    detectedimg75m = insertObjectAnnotation(read(OBJ2,k), 'rectangle', bbox75m, annotation);
    detected_vid_75m(:,:,:,k) = detectedimg75m;
    
end

fclose(fid);
implay(detected_vid_75m);

fid = fopen('ref_75m_720.txt','r');
formatSpec = '%d';

det_vect_75m = fscanf(fid, formatSpec);


m_75m = det_vect_75m(4:4:120);
medie_75m = mean(m_75m);







% === deplasare ===


OBJ3 = VideoReader('inainte_vitezamica_720.mp4');

numar_cadre_depl= get(OBJ3,'NumberOfFrames');
fprintf('Numar de cadre_depl = %d\n', numar_cadre_depl);

label_no_det = cell(numar_cadre_depl,1);

for ii=1:numar_cadre_depl
    
    label_no_det{ii} = ['Stop Sign Undetected!'];
    
end

label2 = cell(numar_cadre_depl,1);

for ii=1:numar_cadre_depl
    
    label2{ii} = ['Stop Sign Detected!'];
    
end


pozitiehd = ones(numar_cadre_depl,4);

%am ales o pozitie unde sa fie afisata distanta pe video

for i= 1 : numar_cadre_depl
    
  pozitiehd(i)=600;
    
end

for j = numar_cadre_depl+1 : numar_cadre_depl*2
             
  pozitiehd(j)=200;
               
end



fid=fopen('inainte_vitezamica_720.txt','w');
fid2=fopen('cadre_fara_detectie_inainte_vitezamica_720.txt','w');

for k = 1 : numar_cadre_depl
   
    [bboxdepl, score, label] = detect(rcnn, read(OBJ3,k), 'MiniBatchSize', 32);
    [score, idx] = max(score);
    bboxdepl = bboxdepl(idx, :);
    if isempty(bboxdepl) == 1
        fprintf(fid2, '%d \n', k );
        detectedimgdepl = insertObjectAnnotation(read(OBJ3,k), 'rectangle',pozitiehd, label_no_det(k),'TextBoxOpacity',1,'FontSize',18,'Color','red');
        detected_vid_depl(:,:,:,k) = detectedimgdepl;
    else
    fprintf(fid, '%d %d %d %d \n', bboxdepl );
    detectedimgdepl = insertObjectAnnotation(read(OBJ3,k), 'rectangle', bboxdepl, annotation);
    detected_vid_depl(:,:,:,k) = detectedimgdepl;
    
    detectedimgdepl = insertObjectAnnotation(detected_vid_depl(:,:,:,k), 'rectangle', pozitiehd, label2(k),'TextBoxOpacity',1,'FontSize',18,'Color','green');
    detected_vid_depl(:,:,:,k) = detectedimgdepl;
    end
    
end

fclose(fid);
fclose(fid2);

fid = fopen('inainte_vitezamica_720.txt','r');
formatSpec = '%d';

det_vect_depl = fscanf(fid, formatSpec);
fclose(fid);
implay(detected_vid_depl);

fid2 = fopen('cadre_fara_detectie_inainte_vitezamica_720.txt','r');
formatSpec = '%d';

no_detection = fscanf(fid2, formatSpec);

fclose(fid2);

% === Distance Calculation ===


fid=fopen('distance_inainte_vitezamica_720.txt','w');

dref = 7.54;
yref = medie_75m;
ddifref = 7.54 - 5.05;
ydifref = abs(medie_5m - medie_75m);
numar_cadre_cu_detectie = numar_cadre_depl - length(no_detection);

 
for j = 4:4:numar_cadre_cu_detectie*4
    
    ydif = abs(yref - det_vect_depl(j));
    ddif = (ydif*ddifref)/ydifref;
    
    if det_vect_depl(j) < yref
        dfinal = dref + ddif;
    else
        dfinal = abs(dref - ddif);
    end

    fprintf(fid, '%.2f \n', dfinal );
    
end

fclose(fid);

fid = fopen('distance_inainte_vitezamica_720.txt','r');
formatSpec = '%f';

distance = fscanf(fid, formatSpec);

fclose(fid);



% === Show Distance ===


label_str = cell(numar_cadre_cu_detectie,1);

for ii=1:numar_cadre_cu_detectie
    
     
    label_str{ii} = ['Distance to Sign : ' num2str(distance(ii),'%f') 'm'];
    
    
end

pozitie = ones(numar_cadre_depl,4);

%am ales o pozitie unde sa fie afisata distanta pe video

for i= 1 : numar_cadre_depl
    
  pozitie(i)=530;
    
end

for j = numar_cadre_depl+1 : numar_cadre_depl*2
             
  pozitie(j)=233;
               
end


%afisare
index = 0;
OBJ4 = VideoReader('inainte_vitezamica_720.mp4');

for k = 1:numar_cadre_depl
    
 [bboxdepl, score, label] = detect(rcnn, read(OBJ4,k), 'MiniBatchSize', 32);
 [score, idx] = max(score);
 bboxdepl = bboxdepl(idx, :);
 if isempty(bboxdepl) == 1
 index = index + 1;
 detplusdist = insertObjectAnnotation(detected_vid_depl(:,:,:,k), 'rectangle',pozitiehd, label_no_det(k),'TextBoxOpacity',1,'FontSize',18,...
                                                                                                                        'Color','red');
 detected_vid_dist(:,:,:,k) = detplusdist;
    
 else
detplusdist = insertObjectAnnotation(detected_vid_depl(:,:,:,k), 'rectangle', pozitie , label_str(abs(k-index)),'TextBoxOpacity',1,'FontSize',18,...
                                                                                                                            'Color','green');
detected_vid_dist(:,:,:,k) = detplusdist;
 end
 
 
end


implay(detected_vid_dist,30);







% Projmp4=VideoWriter('ProiectAPDSV.mp4','MPEG-4');
% open(Projmp4);
% writeVideo(Projmp4,detected_vid_dist);

% close(Projmp4);