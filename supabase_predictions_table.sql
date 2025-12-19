-- Create predictions table for storing genetic disease prediction results
CREATE TABLE public.predictions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    disease VARCHAR(100) NOT NULL,
    probability DECIMAL(5,4) NOT NULL CHECK (probability >= 0 AND probability <= 1),
    risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('Very Low', 'Low', 'Moderate', 'High', 'Very High')),
    form_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) TABLESPACE pg_default;

-- Create index for better query performance
CREATE INDEX idx_predictions_user_id ON public.predictions(user_id);
CREATE INDEX idx_predictions_created_at ON public.predictions(created_at DESC);
CREATE INDEX idx_predictions_disease ON public.predictions(disease);
CREATE INDEX idx_predictions_risk_level ON public.predictions(risk_level);

-- Enable Row Level Security (RLS)
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Create RLS policy to allow users to only see their own predictions
CREATE POLICY "Users can view their own predictions" ON public.predictions
    FOR SELECT USING (auth.uid() = user_id);

-- Create RLS policy to allow users to insert their own predictions
CREATE POLICY "Users can insert their own predictions" ON public.predictions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create RLS policy to allow users to update their own predictions
CREATE POLICY "Users can update their own predictions" ON public.predictions
    FOR UPDATE USING (auth.uid() = user_id);

-- Create RLS policy to allow users to delete their own predictions
CREATE POLICY "Users can delete their own predictions" ON public.predictions
    FOR DELETE USING (auth.uid() = user_id);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_predictions_updated_at 
    BEFORE UPDATE ON public.predictions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE public.predictions IS 'Stores genetic disease prediction results for users';
COMMENT ON COLUMN public.predictions.id IS 'Unique identifier for each prediction';
COMMENT ON COLUMN public.predictions.user_id IS 'Reference to the user who made the prediction';
COMMENT ON COLUMN public.predictions.disease IS 'The predicted genetic disease';
COMMENT ON COLUMN public.predictions.probability IS 'Prediction probability (0.0 to 1.0)';
COMMENT ON COLUMN public.predictions.risk_level IS 'Risk level classification';
COMMENT ON COLUMN public.predictions.form_data IS 'JSON data containing input parameters used for prediction';
COMMENT ON COLUMN public.predictions.created_at IS 'Timestamp when the prediction was created';
COMMENT ON COLUMN public.predictions.updated_at IS 'Timestamp when the prediction was last updated';