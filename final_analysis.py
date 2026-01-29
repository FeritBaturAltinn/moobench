import pandas as pd
import glob
import os

KIEKER_DIR = "frameworks/Kieker-python/results-Kieker-python"
OTEL_DIR   = "frameworks/OpenTelemetry-python/results"

def calculate_mean(directory, file_prefix, config_index):
    pattern = os.path.join(directory, f"{file_prefix}-*-*-{config_index}.csv")
    files = glob.glob(pattern)
    
    if not files:
        print(f"  [!] No files found for Config {config_index} in {directory}")
        return 0

    all_data = []
    print(f"  -> Found {len(files)} files for Config {config_index}...")
    
    for file in files:
        try:
            df = pd.read_csv(file, sep=";", header=None, names=["Thread", "Duration"])
            
            # ignore warmup state
            cutoff = len(df) // 2
            steady_state = df.iloc[cutoff:]
            all_data.append(steady_state)
        except Exception as e:
            print(f"Error reading {file}: {e}")

    if not all_data:
        return 0
        
    combined = pd.concat(all_data)
    mean_val = combined["Duration"].mean()
    return mean_val

def main():
    print("Performance Comparison")

    otel_baseline = calculate_mean(OTEL_DIR, "results", 0)
    otel_internal = calculate_mean(OTEL_DIR, "results", 1) # No Export
    otel_zipkin   = calculate_mean(OTEL_DIR, "results", 2) # Zipkin

    kieker_baseline = calculate_mean(KIEKER_DIR, "raw", 0)
    kieker_internal = calculate_mean(KIEKER_DIR, "raw", 3) # No Logging
    kieker_tcp      = calculate_mean(KIEKER_DIR, "raw", 7) # TCP

    otel_cost_internal = otel_internal - otel_baseline
    otel_cost_full     = otel_zipkin - otel_baseline
    
    kieker_cost_internal = kieker_internal - kieker_baseline
    kieker_cost_full     = kieker_tcp - kieker_baseline

    print(f"BASELINE (Python):           {otel_baseline:.2f} ns")
    print("-" * 50)
    
    print("INTERNAL OVERHEAD (Collecting data, no network)")
    print(f"  OpenTelemetry: {otel_cost_internal:.2f} ns")
    print(f"  Kieker:        {kieker_cost_internal:.2f} ns")
    
    print("-" * 50)
    print("FULL OVERHEAD (Collecting + Sending)")
    print(f"  OpenTelemetry: {otel_cost_full:.2f} ns")
    print(f"  Kieker:        {kieker_cost_full:.2f} ns")

    if otel_cost_full < kieker_cost_full:
        print(f"OpenTelemetry is FASTER by {(kieker_cost_full - otel_cost_full):.2f} ns")
    else:
        print("Kieker is FASTER.")

if __name__ == "__main__":
    main()