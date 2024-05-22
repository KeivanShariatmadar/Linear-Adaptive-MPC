% Function which returns the Objective Function for x to be minimized
%
%
%
% Author: Spiros Papadopoulos
%

function Jxy = objFuncXY(Duxy,uxPrev,uyPrev,ft,simOut,refVectorX,refVectorY,refVectorXDot,refVectorYDot,quad,mpcParams)
    
    % Extract phi,theta,psi from Sim
    phi = simOut.states(end,1); 
    theta = simOut.states(end,2);
    psi = simOut.states(end,3);

    % Extract x, x' from Sim
    xLast = simOut.states(end,10);
    xDotLast = cos(theta)*cos(psi)  * (simOut.states(end,7)) + ...
               simOut.states(end,8) * (sin(phi)*sin(theta)*cos(psi) - ...
               cos(phi)*sin(psi)) + ...
               simOut.states(end,9) * ((cos(phi)*sin(theta)*cos(psi)) + (sin(phi)*sin(psi))); 

    % Extract y, y' from Sim
    yLast = simOut.states(end,11);
    yDotLast = (cos(theta)*sin(psi))*simOut.states(end,7) + ((sin(phi)*sin(theta)*sin(psi)) + ...
               (cos(phi)*cos(psi)))*simOut.states(end,8)  + ((cos(phi)*sin(theta)*sin(psi)) - ...
               (sin(phi)*cos(psi)))*simOut.states(end,9);
 
    %% Get MPC parameters
    Nc = mpcParams.Nc;
    Np = mpcParams.Np;

    Q = mpcParams.Q;
    R = mpcParams.R;

    %-----%
    %  x  %
    %-----%

    Dux = Duxy(:,1)';

    %% Calculate new ux -- Dimensions: (Npx1) 
    for i = 1:Nc
        ux(i) = Duxy(i,1) + uxPrev;
        uxPrev = ux(i);
    end

    %% Implement equality constraint -- Dux(i)=0,  i=Nc+1,...,Np
    % If Control Horizon is smaller than Prediction Horizon, keep last calculated ux for the rest 
    ux(Nc+1:Np) = ux(Nc);

    %% Use Prediction Model (Linear for this case) to predict [x{k+1} x{k+1}']
    
    % [x x']
    xPrev = [xLast xDotLast]';
    
    % Use Linear Prediction Model for x, x' predictions & Create Prediction Vector
    [x1Vector, x2Vector] = createPredictionVectorX(xPrev, ft, ux(:), Np, quad);
       
    xPrev = [x1Vector(end) x2Vector(end)];

    % Create Error Vector for x position
    xPredError = refVectorX - x1Vector;

    % Create Error Vector for x velocity
    xDotPredError = refVectorXDot - x2Vector;

    %% Return Objective Function Evaluation
    Jx = xPredError*Q*xPredError' + Dux*R*Dux' + xDotPredError*(0.01*Q)*xDotPredError'; % Dimensions: (1xNp)*(NpxNp)*(Npx1) + (1xNc)*(NcxNc)*(Ncx1)

    %-----%
    %  y  %
    %-----%

    Duy = Duxy(:,2)';

     %% Calculate new uy -- Dimensions: (Npx1) 
    for i = 1:Nc
        uy(i) = Duxy(i,2) + uyPrev;
        uyPrev = uy(i);
    end

    %% Implement equality constraint -- Duy(i)=0,  i=Nc+1,...,Np
    % If Control Horizon is smaller than Prediction Horizon, keep last calculated uy for the rest 
    uy(Nc+1:Np) = uy(Nc);

    %% Use Prediction Model (Linear for this case) to predict [y{k+1} y{k+1}']
    
    % [y y']
    yPrev = [yLast yDotLast]';
    
    % Use Linear Prediction Model for y, y' predictions & Create Prediction Vector
    [y1Vector, y2Vector] = createPredictionVectorY(yPrev, ft, uy, Np, quad);
      
    yPrev = [y1Vector(end) y2Vector(end)];

    % Create Error Vector  for y position
    yPredError = refVectorY - y1Vector;

    % Create Error Vector for y velocity
    yDotPredError = refVectorYDot - y2Vector;

    %% Return Objective Function Evaluation
    Jy = yPredError*Q*yPredError' + Duy*R*Duy' + yDotPredError*(0.01*Q)*yDotPredError'; % Dimensions: (1xNp)*(NpxNp)*(Npx1) + (1xNc)*(NcxNc)*(Ncx1)    


    %% Calculate final Objective Function Jxy

    Jxy = Jx + Jy;


end
