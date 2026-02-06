using System;
using System.Collections.Generic;

namespace ManejoPresupuestos.Models
{
    public class ReporteProduccionUtilizacionViewModel
    {
        // Filtros
        public DateTime? Desde { get; set; }
        public DateTime? Hasta { get; set; }
        public int? ImpresoraId { get; set; }
        public bool IncluirEnCurso { get; set; } = true;
        public bool IncluirSinImpresora { get; set; } = true;
        public string? Q { get; set; }

        // Data
        public ReporteProduccionUtilizacionTotalesDto Totales { get; set; } = new();
        public List<ReporteProduccionUtilizacionPorImpresoraDto> PorImpresora { get; set; } = new();
        public List<ReporteProduccionUtilizacionDetalleDto> Detalle { get; set; } = new();

        // Catalogos
        public List<CatalogoImpresoraDto> CatImpresoras { get; set; } = new();
    }
}