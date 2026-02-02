using System.Collections.Generic;

namespace ManejoPresupuestos.Models
{
    public class TarifasIndexViewModel
    {
        public List<TarifaSelectorInventarioDto> Inventarios { get; set; } = new();
        public List<TarifaSelectorImpresoraDto> Impresoras { get; set; } = new();
    }
}