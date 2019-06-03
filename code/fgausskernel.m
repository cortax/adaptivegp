classdef fgausskernel < matlab.mixin.Copyable

    properties
        x_timegrid
        loggamma_
        loglambda_
        
        T
        D
        
        K
        Kinv
        
        gpprior
        
        id
    end
    
    properties (Dependent)
        theta
        loggamma
        loglambda
        nb_param
    end
    
    methods
        function obj = fgausskernel(x_timegrid, loggamma, loglambda)
            obj.x_timegrid = tocolumn(x_timegrid);
            obj.loggamma = tocolumn(loggamma);
            obj.loglambda = tocolumn(loglambda);
            
            obj.T = size(obj.x_timegrid,1);
			obj.D = pdist2(obj.x_timegrid,obj.x_timegrid).^2;
            
            obj.unlinkprior();
            
            obj.update_covariance();
            obj.id = randi(100000000);
        end
        
        function update_covariance(obj)
            obj.K = obj.kernel(obj.x_timegrid, obj.x_timegrid, exp(obj.loggamma), exp(obj.loggamma), exp(obj.loglambda), exp(obj.loglambda));
            obj.Kinv = pdinv(obj.K);
        end
        
        function linkprior(obj, gpprior_loggamma, gpprior_loglambda)
            obj.gpprior.loggamma = gpprior_loggamma;
            obj.gpprior.loglambda = gpprior_loglambda;
        end
        
        function unlinkprior(obj)
            obj.gpprior.loggamma = [];
            obj.gpprior.loglambda = [];
        end
        
        function [gradient, gradientY] = gradient_dtheta(obj, Y, parent_gp)
            [gradient_dloggamma, gradient_dloggammaY] = obj.gradient_dloggamma(Y, parent_gp);
            [gradient_dloglambda, gradient_dloglambdaY] = obj.gradient_dloglambda(Y, parent_gp);
            gradient = [gradient_dloggamma; gradient_dloglambda];
            gradientY = [gradient_dloggammaY; gradient_dloglambdaY];
        end
        
        function [gradient, gradientY] = gradient_dloggamma(obj, Y, parent_gp)
            gradientY = zeros(size(Y));
            for i_data = 1:size(Y,2)
                a = parent_gp.Kinv*(Y(:,i_data) - parent_gp.m);
                gradientY(:,i_data) = sum((a*a' - parent_gp.Kinv).*obj.K, 2);
            end
            gradient = sum(gradientY,2);
        end
        
        function [gradient, gradientY] = gradient_dloglambda(obj, Y, parent_gp)
            lambda = exp(obj.loglambda);
            gamma = exp(obj.loggamma);

            L = repmat(lambda.^2,1,obj.T) + repmat(lambda.^2,1,obj.T)';
            E = exp(-obj.D./L);
            R = sqrt( 2*(lambda*lambda') ./ L );
            dK = (lambda*lambda') .* (gamma*gamma') .* E .* (R.^(-1)) .* (L.^(-3)) .* (4 * obj.D .* repmat(lambda.^2,1,obj.T) - repmat(lambda.^4,1,obj.T) + repmat(lambda'.^4,obj.T,1));

            A = parent_gp.Kinv*(Y - repmat(parent_gp.m, 1, size(Y,2)));
            gradientY = A.*(A'*dK')' - repmat(sum(parent_gp.Kinv.*dK,2),1,size(Y,2));
            gradient = sum(A.*(A'*dK')',2) + -size(Y,2)*sum(parent_gp.Kinv.*dK,2);
        end
        
		function set.loggamma(obj, loggamma)
            obj.K = [];
            obj.Kinv = [];
			obj.loggamma_ = tocolumn(loggamma);
        end
        
        function set.theta(obj, theta)
            n = length(theta);
            obj.loggamma = theta(1:(n/2));
            obj.loglambda = theta((1+n/2):n);
        end
        
        function theta = get.theta(obj)
            theta = [obj.loggamma_; obj.loglambda_];
        end
        
        function set.loglambda(obj, loglambda)
            obj.K = [];
            obj.Kinv = [];
			obj.loglambda_ = tocolumn(loglambda);
        end
        
		function loggamma = get.loggamma(obj)
			loggamma = obj.loggamma_;
        end
        
		function loglambda = get.loglambda(obj)
			loglambda = obj.loglambda_;
        end
        
        function K = get.K(obj)
            if isempty(obj.K)
                obj.update_covariance();
            end
			K = obj.K;
        end
        
        function Kinv = get.Kinv(obj)
            if isempty(obj.Kinv)
                obj.update_covariance();
            end
			Kinv = obj.Kinv;
        end
        
        function n = get.nb_param(obj)
            n = length(obj.loggamma_) + length(obj.loglambda_);
        end
    end
    
    methods (Static)
        function K = kernel(x_timegridA, x_timegridB, gammaA, gammaB, lambdaA, lambdaB)
            sumcross = @(v1,v2) repmat(v1,1,size(v2,1)) + repmat(v2',size(v1,1),1);
            K = gammaA*gammaB' .* sqrt((2*lambdaA*lambdaB')./sumcross(lambdaA.^2,lambdaB.^2)) .* exp(- (pdist2(x_timegridA,x_timegridB).^2 ./ sumcross(lambdaA.^2,lambdaB.^2)));
        end
    end

end

