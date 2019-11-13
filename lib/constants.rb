YesNo  = ["Yes", "No"]
SpcRE  = /[[:space:]]+/
Cmpnts = ["ecs",
          "ecr",
          "ssm",
          "r53",
]
MxPler = {:h => 3600, :m => 60, :d => 86400, :Gi => 1024, :Ki => 1/1024.0 }
Nrm    = Proc.new { |v,u| v.to_i * (MxPler[(u||"").to_sym] || 1) }
