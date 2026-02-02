using System.Collections.Generic;
using System.Linq;

namespace ManejoPresupuestos.Models
{
    public class CosteoResumenDto
    {
        public string Moneda { get; set; } = "MXN";
        public List<CosteoDetalleDto> Detalles { get; set; } = new();

        public decimal Total => Detalles.Sum(x => x.Subtotal);
    }
}