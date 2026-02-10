import pandas as pd
import glob
import os

KIEKER_DIR = "frameworks/Kieker-python/results-Kieker-python/results"
OTEL_DIR   = "frameworks/OpenTelemetry-python/results"

def calculate_mean(directory, file_prefix, config_index):
    # Find all files for this config (loops 1 through 10)
    pattern = os.path.join(directory, f"{file_prefix}-*-*-{config_index}.csv")
    files = glob.glob(pattern)
    
    if not files:
        return None

    all_data = []
    for file in files:
        try:
            df = pd.read_csv(file, sep=";", header=None, names=["Thread", "Duration"])
            # Remove warmup (first half)
            cutoff = len(df) // 2
            steady_state = df.iloc[cutoff:]
            all_data.append(steady_state)
        except:
            pass

    if not all_data: return None
    
    # Combine all 10 loops
    combined = pd.concat(all_data)
    
    # Return Mean and Standard Deviation
    return {
        "mean": combined["Duration"].mean(),
        "std": combined["Duration"].std(),
        "count": len(files)
    }

def main():
    print(f"{'FINAL RESULTS':^60}")

    otel_baseline = calculate_mean(OTEL_DIR, "results", 0)
    otel_internal = calculate_mean(OTEL_DIR, "results", 1) # No Export
    otel_zipkin   = calculate_mean(OTEL_DIR, "results", 2) # Zipkin

    kieker_baseline = calculate_mean(KIEKER_DIR, "raw", 0)
    kieker_internal = calculate_mean(KIEKER_DIR, "raw", 3) # No Logging
    kieker_tcp      = calculate_mean(KIEKER_DIR, "raw", 7) # TCP

    print(f"\n{'CONFIGURATION':<25} | {'MEAN (ns)':<15} | {'STD DEV':<15}")
    
    def p_row(name, stats):
        if stats:
            print(f"{name:<25} | {stats['mean']:<15.2f} | {stats['std']:<15.2f}")
        else:
            print(f"{name:<25} | {'MISSING':<15} | -")
    p_row("Baseline (Python)", otel_baseline)
    p_row("OTel Internal", otel_internal)
    p_row("OTel Zipkin", otel_zipkin)
    p_row("Kieker Internal", kieker_internal)
    p_row("Kieker TCP", kieker_tcp)

    if otel_zipkin and kieker_tcp:
        otel_overhead = otel_zipkin['mean'] - otel_baseline['mean']
        kieker_overhead = kieker_tcp['mean'] - kieker_baseline['mean']
        
        print(f"\nOVERHEAD COMPARISON:")
        print(f"OpenTelemetry Overhead: {otel_overhead:.2f} ns")
        print(f"Kieker Overhead:        {kieker_overhead:.2f} ns")
        
        if otel_overhead < kieker_overhead:
            factor = kieker_overhead / otel_overhead
            print(f"\nOpenTelemetry is {factor:.1f}x FASTER than Kieker.")
        else:
            print(f"\nKieker is FASTER.")

if __name__ == "__main__":
    main()